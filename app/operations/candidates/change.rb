# frozen_string_literal: true

class Candidates::Change
  include Dry::Monads[:result, :do, :try]

  include Dry::Initializer.define -> do
    option :candidate, Types::Instance(Candidate)
    option :actor_account, Types::Instance(Account)
    option :params, Types::Strict::Hash.schema(
      avatar?: Types::Instance(ActionDispatch::Http::UploadedFile),
      remove_avatar?: Types::Strict::String,
      file?: Types::Instance(ActionDispatch::Http::UploadedFile),
      cover_letter?: Types::Strict::String,
      file_id_to_remove?: Types::Strict::String,
      file_id_to_change_cv_status?: Types::Strict::String,
      new_cv_status?: Types::Strict::String,
      recruiter_id?: Types::Strict::String.optional,
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
    old_values = remember_old_values(candidate)

    params[:emails].uniq! { _1[:address].downcase } if params[:emails].present?
    if params[:phones].present?
      params[:phones].uniq! do |phone_record|
        CandidatePhone.normalize(phone_record[:phone], candidate.location&.country_code || "RU")
      end
    end
    params[:links].uniq! { AccountLink.new(_1[:url]).normalize } if params[:links].present?

    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        candidate.assign_attributes(params.except(:alternative_names))
        candidate.save!

        if params.key?(:alternative_names)
          yield Candidates::AlternativeNames::Change.new(
            candidate:,
            actor_account:,
            alternative_names: params[:alternative_names]
          ).call
        end

        if candidate.recruiter_id != old_values[:recruiter_id]
          add_recruiter_changed_events(
            candidate:,
            actor_account:,
            old_recruiter_id: old_values[:recruiter_id]
          )
        end

        add_changed_events(candidate:, actor_account:, old_values:)
      end
    end.to_result

    case result
    in Success(_)
      Success(candidate)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:candidate_invalid, candidate.errors.full_messages.presence || e.to_s]
    end
  end

  private

  def remember_old_values(candidate)
    {
      recruiter_id: candidate.recruiter_id,
      location: candidate.location,
      full_name: candidate.full_name,
      company: candidate.company,
      blacklisted: candidate.blacklisted,
      headline: candidate.headline,
      telegram: candidate.telegram,
      skype: candidate.skype,
      candidate_source: candidate.source,
      links: candidate.links,
      alternative_names: candidate.names,
      emails: candidate.emails,
      phones: candidate.phones
    }
  end

  def add_recruiter_changed_events(candidate:, actor_account:, old_recruiter_id:)
    if old_recruiter_id.present?
      Events::Add.new(
        params:
          {
            type: :candidate_recruiter_unassigned,
            eventable: candidate,
            changed_from: old_recruiter_id,
            actor_account:
          }
      ).call
    end

    return if candidate.recruiter_id.blank?

    Events::Add.new(
      params:
        {
          type: :candidate_recruiter_assigned,
          eventable: candidate,
          changed_to: candidate.recruiter_id,
          actor_account:
        }
    ).call
  end

  def add_changed_events(candidate:, actor_account:, old_values:)
    Events::AddChangedEvent.new(
      eventable: candidate,
      changed_field: "location",
      old_value: old_values[:location]&.short_name,
      new_value: candidate.location&.short_name,
      actor_account:
    ).call

    Events::AddChangedEvent.new(
      eventable: candidate,
      changed_field: "full_name",
      old_value: old_values[:full_name],
      new_value: candidate.full_name,
      actor_account:
    ).call

    Events::AddChangedEvent.new(
      eventable: candidate,
      changed_field: "company",
      old_value: old_values[:company],
      new_value: candidate.company,
      actor_account:
    ).call

    Events::AddChangedEvent.new(
      eventable: candidate,
      changed_field: "blacklisted",
      old_value: old_values[:blacklisted],
      new_value: candidate.blacklisted,
      actor_account:
    ).call

    Events::AddChangedEvent.new(
      eventable: candidate,
      changed_field: "headline",
      old_value: old_values[:headline],
      new_value: candidate.headline,
      actor_account:
    ).call

    Events::AddChangedEvent.new(
      eventable: candidate,
      changed_field: "telegram",
      old_value: old_values[:telegram],
      new_value: candidate.telegram,
      actor_account:
    ).call

    Events::AddChangedEvent.new(
      eventable: candidate,
      changed_field: "skype",
      old_value: old_values[:skype],
      new_value: candidate.skype,
      actor_account:
    ).call

    Events::AddChangedEvent.new(
      eventable: candidate,
      changed_field: "candidate_source",
      old_value: old_values[:candidate_source],
      new_value: candidate.source,
      actor_account:
    ).call

    Events::AddChangedEvent.new(
      eventable: candidate,
      changed_field: "email_addresses",
      field_type: :plural,
      old_value: old_values[:emails],
      new_value: candidate.emails,
      actor_account:
    ).call

    Events::AddChangedEvent.new(
      eventable: candidate,
      changed_field: "phones",
      field_type: :plural,
      old_value: old_values[:phones],
      new_value: candidate.phones,
      actor_account:
    ).call

    Events::AddChangedEvent.new(
      eventable: candidate,
      changed_field: "links",
      field_type: :plural,
      old_value: old_values[:links],
      new_value: candidate.links,
      actor_account:
    ).call
  end
end
