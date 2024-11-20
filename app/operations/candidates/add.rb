# frozen_string_literal: true

class Candidates::Add < ApplicationOperation
  include Dry::Monads[:do, :result]

  option :actor_account, Types::Instance(Account).optional
  option :params, Types::Strict::Hash.schema(
    avatar?: Types::Instance(ActionDispatch::Http::UploadedFile),
    remove_avatar?: Types::Strict::String,
    cover_letter?: Types::Strict::String,
    file_id_to_remove?: Types::Strict::String,
    file_id_to_change_cv_status?: Types::Strict::String,
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

  def call
    candidate = Candidate.new
    old_values = candidate.attributes.deep_symbolize_keys

    prepared_params = prepare_params(params:, actor_account:)
    candidate.assign_attributes(prepared_params)

    candidate.recruiter_id ||= actor_account&.member&.id

    return Failure[:candidate_invalid, candidate] unless candidate.valid?

    ActiveRecord::Base.transaction do
      yield save_candidate(candidate)
      add_events(candidate:, actor_account:)
      add_changed_events(candidate:, actor_account:, old_values:)
    end

    Success(candidate)
  end

  private

  def save_candidate(candidate)
    candidate.save!

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:candidate_invalid, candidate.errors.full_messages.presence || e.to_s]
  end

  def prepare_params(params:, actor_account:)
    if params[:emails].present?
      params[:emails].uniq! { _1[:address].downcase }
      params[:emails].each do |p|
        p[:created_by] = p[:created_by] || actor_account&.member
      end
    end

    if params[:phones].present?
      country_code =
        if params[:location_id].present?
          Location.find(params[:location_id]).country_code
        else
          "RU"
        end
      params[:phones].uniq! do |phone_record|
        CandidatePhone.normalize(phone_record[:phone], country_code)
      end
      params[:phones].each do |p|
        p[:created_by] = p[:created_by] || actor_account&.member
      end
    end

    if params[:links].present?
      params[:links].uniq! { AccountLink.new(_1[:url]).normalize }
      params[:links].each do |p|
        p[:created_by] = p[:created_by] || actor_account&.member
      end
    end

    params
  end

  def add_events(candidate:, actor_account:)
    Event.create!(
      type: :candidate_added,
      eventable: candidate,
      actor_account:
    )
    Event.create!(
      type: :candidate_recruiter_assigned,
      eventable: candidate,
      actor_account:,
      changed_to: candidate.recruiter_id
    )
  end

  def add_changed_events(candidate:, actor_account:, old_values:)
    Event.create_changed_event_if_value_changed(
      eventable: candidate,
      changed_field: "location",
      old_value: old_values[:location]&.short_name,
      new_value: candidate.location&.short_name,
      actor_account:
    )

    Event.create_changed_event_if_value_changed(
      eventable: candidate,
      changed_field: "full_name",
      old_value: old_values[:full_name],
      new_value: candidate.full_name,
      actor_account:
    )

    Event.create_changed_event_if_value_changed(
      eventable: candidate,
      changed_field: "company",
      old_value: old_values[:company],
      new_value: candidate.company,
      actor_account:
    )

    Event.create_changed_event_if_value_changed(
      eventable: candidate,
      changed_field: "blacklisted",
      old_value: old_values[:blacklisted],
      new_value: candidate.blacklisted,
      actor_account:
    )

    Event.create_changed_event_if_value_changed(
      eventable: candidate,
      changed_field: "headline",
      old_value: old_values[:headline],
      new_value: candidate.headline,
      actor_account:
    )

    Event.create_changed_event_if_value_changed(
      eventable: candidate,
      changed_field: "telegram",
      old_value: old_values[:telegram],
      new_value: candidate.telegram,
      actor_account:
    )

    Event.create_changed_event_if_value_changed(
      eventable: candidate,
      changed_field: "skype",
      old_value: old_values[:skype],
      new_value: candidate.skype,
      actor_account:
    )

    Event.create_changed_event_if_value_changed(
      eventable: candidate,
      changed_field: "candidate_source",
      old_value: old_values[:candidate_source],
      new_value: candidate.source,
      actor_account:
    )

    Event.create_changed_event_if_value_changed(
      eventable: candidate,
      changed_field: "email_addresses",
      field_type: :plural,
      old_value: old_values[:emails],
      new_value: candidate.emails,
      actor_account:
    )

    Event.create_changed_event_if_value_changed(
      eventable: candidate,
      changed_field: "phones",
      field_type: :plural,
      old_value: old_values[:phones],
      new_value: candidate.phones,
      actor_account:
    )

    Event.create_changed_event_if_value_changed(
      eventable: candidate,
      changed_field: "links",
      field_type: :plural,
      old_value: old_values[:links],
      new_value: candidate.links,
      actor_account:
    )
  end
end
