# frozen_string_literal: true

class Candidates::UpdateFromCV < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :cv_file, Types::Instance(ActionDispatch::Http::UploadedFile)
  option :candidate, Types.Instance(Candidate)
  option :actor_account, Types::Instance(Account).optional, optional: true

  def call
    country_code = candidate.location&.country_code
    file_extension = cv_file.original_filename.split(".").last

    return Failure(:unsupported_file_format) if file_extension != "pdf"

    parsed = yield parse_pdf(cv_file)
    data = extract(parsed[:plain_text], country_code:)
    update_contacts(
      data,
      parsed_emails: parsed[:emails],
      parsed_urls: parsed[:urls],
      country_code:,
      actor_account:,
      candidate:
    )
  end

  def parse_pdf(file)
    # CVParser::CVParserError is not loaded before the next line,
    # see https://stackoverflow.com/a/68572572
    parsed = CVParser::Parser.parse_pdf(file.tempfile)
    Success(parsed)
  rescue PDF::Reader::MalformedPDFError, PDF::Reader::InvalidPageError, CVParser::CVParserError => e
    Log.tagged("Candidates::UpdateFromCV") do |log|
      log.warn({ errors: e.message, candidate_id: candidate.id })
    end
    Failure(:parse_failed)
  end

  def extract(text_to_parse, country_code:)
    CVParser::Content.extract_from_text(text_to_parse, country_code:)
  end

  def update_contacts(data, parsed_emails:, parsed_urls:, country_code:, actor_account:, candidate:)
    phones = (candidate.candidate_phones.map do |candidate_phone|
                candidate_phone
                  .slice(:phone, :list_index, :status, :source, :type, :created_via).symbolize_keys
              end +
              data.phones.filter_map do |phone|
                next unless CandidatePhone.valid_phone?(phone, country_code)

                {
                  phone: CandidatePhone.normalize(phone, country_code),
                  status: "current",
                  type: "personal"
                }
              end)
    phones.uniq! { _1[:phone] }
    phones.select! { _1[:phone].present? }

    parsed_emails = parsed_emails.map { { address: _1 } }
    emails_from_cv = (data.emails + parsed_emails).filter_map do |email|
      email[:status] = "current"
      email[:type] = "personal"
      email[:address] = Normalizer.email_address(email[:address])
      next unless CandidateEmailAddress.valid_email?(email[:address])

      email
    end
    emails = candidate.candidate_email_addresses.map do |email_address|
      email_address
        .slice(:address, :list_index, :status, :source, :type, :created_via).symbolize_keys
    end + emails_from_cv
    emails.uniq! { _1[:address] }
    emails.select! { _1[:address].present? }

    links_from_cv = (parsed_urls.presence || data.urls).filter_map do |url|
      normalized_url =
        begin
          AccountLink.new(url).normalize
        rescue Addressable::URI::InvalidURIError
          ""
        end
      link_is_valid = CandidateLink.valid_link?(normalized_url)
      link_is_blacklisted = AccountLink.new(normalized_url).blacklisted?
      next if !link_is_valid || link_is_blacklisted

      { url: normalized_url, added_at: Time.zone.now, created_via: :api }
    end
    links = candidate.candidate_links.map do |link|
      link.slice(:url, :status, :created_via, :added_at, :created_by_id).symbolize_keys
    end + links_from_cv
    links.uniq! { _1[:url] }
    links.select! { _1[:url].present? }

    case Candidates::Change.new(
      candidate:,
      actor_account:,
      params: { phones:, links:, emails: }
    ).call
    in Success(_)
      Success()
    in Failure[:candidate_invalid, _]
      Log.tagged("Candidates::UpdateFromCV") do |log|
        log.warn(
          {
            errors: candidate.errors.full_messages,
            candidate_id: candidate.id,
            phones:,
            links:,
            emails:
          }
        )
      end
      Failure(:contacts_not_updated)
    end
  end
end
