# frozen_string_literal: true

class Candidates::UpdateFromCV < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :cv_file, Types::Instance(ActionDispatch::Http::UploadedFile)
  option :candidate, Types.Instance(Candidate)
  option :actor_account, Types::Instance(Account).optional, optional: true

  def call
    country_code = candidate.location&.country_code
    file = yield convert_cv_to_pdf(cv_file)
    parsed = yield parse_pdf(file)
    data = extract(parsed[:plain_text], country_code:)
    update_contacts(
      data,
      parsed_emails: parsed[:emails],
      parsed_urls: parsed[:urls],
      country_code:,
      actor_account:
    )
  end

  def convert_cv_to_pdf(file)
    splitted_name = file.original_filename.split(".")
    filename_extension = splitted_name.pop
    return Success(file) if filename_extension == "pdf"

    unless filename_extension.in?(%w[docx doc odt rtf])
      return Failure[:unsupported_file_format, "Unsupported file format",
                     { filename_extension:, candidate_id: candidate.id }]
    end

    begin
      pdf_tempfile = Tempfile.new([splitted_name.join("."), ".pdf"])
      Libreconv.convert(file.path, pdf_tempfile.path)
    rescue StandardError => e
      return Failure[:convert_cv_to_pdf, "Error converting file to PDF",
                     { errors: e.message, candidate_id: candidate.id }]
    end

    Success(pdf_tempfile)
  end

  def parse_pdf(file)
    begin
      parsed = CVParser::Parser.parse_pdf(file.tempfile)
    rescue PDF::Reader::MalformedPDFError, PDF::Reader::InvalidPageError => e
      return Failure[:invalid_pdf, "Invalid PDF file",
                     { errors: e.message, candidate_id: candidate.id }]
    rescue CVParser::CVParserError => e
      return Failure[:parse_pdf, "Error converting from PDF to text",
                     { errors: e.message, candidate_id: candidate.id }]
    end
    Success(parsed)
  end

  def extract(text_to_parse, country_code:)
    CVParser::Content.extract_from_text(text_to_parse, country_code:)
  end

  def update_contacts(data, parsed_emails:, parsed_urls:, country_code:, actor_account:)
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
      Failure[
        :update_contacts,
        "Contacts have not been updated",
        { errors: candidate.errors.full_messages,
          candidate_id: candidate.id,
          phones:,
          links:,
          emails: }
      ]
    end
  end
end
