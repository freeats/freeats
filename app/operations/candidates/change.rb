# frozen_string_literal: true

class Candidates::Change
  include Dry::Monads[:result]

  # TODO: pass actor_user
  include Dry::Initializer.define -> do
    option :candidate, Types::Instance(Candidate)
    option :params, Types::Strict::Hash
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

    ActiveRecord::Base.transaction do
      candidate.assign_attributes(params)
      candidate.save!
      # TODO: create events
    end
    Success()
  rescue ActiveRecord::RecordInvalid
    Failure("record_invalid")
  end
end
