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
    # old_links = candidate.links
    # old_alternative_names = candidate.alternative_names
    # old_emails = candidate.email_addresses
    # old_phones = candidate.phones
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
