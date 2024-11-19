# frozen_string_literal: true

class Positions::Change < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :position, Types::Instance(Position)
  option :params, Types::Strict::Hash.schema(
    name?: Types::Strict::String,
    recruiter_id?: Types::Strict::String.optional,
    location_id?: Types::Strict::String.optional,
    collaborator_ids?: Types::Strict::Array.of(Types::Strict::String.optional),
    hiring_manager_ids?: Types::Strict::Array.of(Types::Strict::String.optional),
    interviewer_ids?: Types::Strict::Array.of(Types::Strict::String.optional),
    description?: Types::Strict::String
  ).strict
  option :actor_account, Types::Instance(Account)

  def call
    old_values = {
      name: position.name,
      recruiter_id: position.recruiter_id,
      location: position.location,
      description: position.description.to_s,
      collaborator_ids: position.collaborator_ids,
      hiring_manager_ids: position.hiring_manager_ids,
      interviewer_ids: position.interviewer_ids
    }

    position.assign_attributes(params)

    ActiveRecord::Base.transaction do
      yield save_position(position)
      add_events(old_values:, position:, actor_account:)
    end

    Success(position.reload)
  end

  private

  def save_position(position)
    position.save!

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:position_invalid, position.errors.full_messages.presence || e.to_s]
  end

  def add_events(old_values:, position:, actor_account:)
    common_event_params = { actor_account:, eventable: position }

    add_changed_recruiter_events(old_values:, position:, common_event_params:)
    add_changed_collaborators_events(old_values:, position:, common_event_params:)
    add_changed_hiring_managers_events(old_values:, position:, common_event_params:)
    add_changed_interviewers_events(old_values:, position:, common_event_params:)
    add_position_changed_events(old_values:, position:, actor_account:)
  end

  def add_changed_recruiter_events(old_values:, position:, common_event_params:)
    return if old_values[:recruiter_id] == position.recruiter_id

    if old_values[:recruiter_id].present?
      Event.create!(
        **common_event_params,
        type: :position_recruiter_unassigned,
        changed_from: old_values[:recruiter_id]
      )
    end

    return if position.recruiter_id.blank?

    Event.create!(
      **common_event_params,
      type: :position_recruiter_assigned,
      changed_to: position.recruiter_id
    )
  end

  def add_changed_collaborators_events(old_values:, position:, common_event_params:)
    position_collaborator_ids = position.collaborator_ids

    return if old_values[:collaborator_ids] == position_collaborator_ids

    removed_collaborator_ids = old_values[:collaborator_ids] - position_collaborator_ids
    removed_collaborator_ids.each do |removed_collaborator_id|
      Event.create!(
        **common_event_params,
        type: :position_collaborator_unassigned,
        changed_from: removed_collaborator_id
      )
    end

    return if position_collaborator_ids.blank?

    added_collaborator_ids = position_collaborator_ids - old_values[:collaborator_ids]
    added_collaborator_ids.each do |added_collaborator_id|
      Event.create!(
        **common_event_params,
        type: :position_collaborator_assigned,
        changed_to: added_collaborator_id
      )
    end
  end

  def add_changed_hiring_managers_events(old_values:, position:, common_event_params:)
    position_hiring_manager_ids = position.hiring_manager_ids

    return if old_values[:hiring_manager_ids] == position_hiring_manager_ids

    removed_hiring_manager_ids = old_values[:hiring_manager_ids] - position_hiring_manager_ids
    removed_hiring_manager_ids.each do |removed_hiring_manager_id|
      Event.create!(
        **common_event_params,
        type: :position_hiring_manager_unassigned,
        changed_from: removed_hiring_manager_id
      )
    end

    return if position_hiring_manager_ids.blank?

    added_hiring_manager_ids = position_hiring_manager_ids - old_values[:hiring_manager_ids]
    added_hiring_manager_ids.each do |added_hiring_manager_id|
      Event.create!(
        **common_event_params,
        type: :position_hiring_manager_assigned,
        changed_to: added_hiring_manager_id
      )
    end
  end

  def add_changed_interviewers_events(old_values:, position:, common_event_params:)
    position_interviewer_ids = position.interviewer_ids

    return if old_values[:interviewer_ids] == position_interviewer_ids

    removed_interviewer_ids = old_values[:interviewer_ids] - position_interviewer_ids
    removed_interviewer_ids.each do |removed_interviewer_id|
      Event.create!(
        **common_event_params,
        type: :position_interviewer_unassigned,
        changed_from: removed_interviewer_id
      )
    end

    return if position_interviewer_ids.blank?

    added_interviewer_ids = position_interviewer_ids - old_values[:interviewer_ids]
    added_interviewer_ids.each do |added_interviewer_id|
      Event.create!(
        **common_event_params,
        type: :position_interviewer_assigned,
        changed_to: added_interviewer_id
      )
    end
  end

  def add_position_changed_events(old_values:, position:, actor_account:)
    eventable = position
    type = :position_changed

    if old_values[:name] != position.name
      position_changed_params = {
        actor_account:,
        type:,
        eventable:,
        changed_field: :name,
        changed_from: old_values[:name],
        changed_to: position.name
      }

      Event.create!(position_changed_params)
    end

    if old_values[:description] != position.description.to_s
      position_changed_params = {
        actor_account:,
        type:,
        eventable:,
        changed_field: :description,
        changed_from: old_values[:description].to_s,
        changed_to: position.description.to_s
      }

      Event.create!(position_changed_params)
    end

    Events::AddChangedEvent.new(
      eventable: position,
      changed_field: "location",
      old_value: old_values[:location]&.short_name,
      new_value: position.location&.short_name,
      actor_account:
    ).call
  end
end
