# frozen_string_literal: true

class Candidates::Change
  include Dry::Monads[:result, :do, :try]

  # TODO: pass actor_user
  include Dry::Initializer.define -> do
    option :candidate, Types::Instance(Candidate)
    option :params, Types::Strict::Hash.schema(
      avatar?: Types::Instance(ActionDispatch::Http::UploadedFile),
      remove_avatar?: Types::Strict::String,
      file?: Types::Instance(ActionDispatch::Http::UploadedFile),
      cover_letter?: Types::Strict::String,
      file_id_to_remove?: Types::Strict::String,
      file_id_to_change_cv_status?: Types::Strict::String,
      new_cv_status?: Types::Strict::String,
      recruiter_id?: Types::Strict::String,
      location_id?: Types::Strict::String,
      full_name?: Types::Strict::String,
      company?: Types::Strict::String,
      blacklisted?: Types::Strict::String,
      headline?: Types::Strict::String,
      telegram?: Types::Strict::String,
      skype?: Types::Strict::String,
      source?: Types::Strict::String,
      links?: Types::Strict::Array.of(
        Types::Strict::Hash.schema(
          url: Types::Strict::String,
          status: Types::Strict::String
        ).optional
      ),
      alternative_names?: Types::Strict::Array.of(
        Types::Strict::Hash.schema(
          name: Types::Strict::String
        ).optional
      ),
      emails?: Types::Strict::Array.of(
        Types::Strict::Hash.schema(
          address: Types::Strict::String,
          status: Types::Strict::String,
          url?: Types::Strict::String,
          source: Types::Strict::String,
          type: Types::Strict::String
        ).optional
      ),
      phones?: Types::Strict::Array.of(
        Types::Strict::Hash.schema(
          phone: Types::Strict::String,
          status: Types::Strict::String,
          source: Types::Strict::String,
          type: Types::Strict::String
        ).optional
      )
    )
  end

  def call
    # # Fields
    # old_recruiter_id = candidate.recruiter_id
    # old_location_id = candidate.location_id
    # old_full_name = candidate.full_name
    # old_company = candidate.company
    # old_blacklisted = candidate.blacklisted
    # old_headline = candidate.headline
    # old_telegram = candidate.telegram
    # old_skype = candidate.skype
    # old_candidate_source = candidate.candidate_source

    # # Associations
    # old_links = candidate.candidate_links
    # old_alternative_names = candidate.candidate_alternative_names
    # old_emails = candidate.candidate_email_addresses
    # old_phones = candidate.candidate_phones

    params[:emails].uniq! { _1[:address].downcase } if params[:emails].present?
    if params[:phones].present?
      params[:phones].uniq! do |phone_record|
        CandidatePhone.normalize(phone_record[:phone], candidate.location&.country_code || "RU")
      end
    end
    params[:links].uniq! { AccountLink.new(_1[:url]).normalize } if params[:links].present?

    candidate.assign_attributes(params.except(:alternative_names))

    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        candidate.save!

        if params.key?(:alternative_names)
          yield Candidates::AlternativeNames::Change.new(
            candidate:,
            alternative_names: params[:alternative_names]
          ).call
        end

        # TODO: create events
      end
    end.to_result

    case result
    in Success(_)
      Success()
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:candidate_invalid, candidate.errors.full_messages.presence || e.to_s]
    end
  end
end
