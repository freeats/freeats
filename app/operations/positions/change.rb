# frozen_string_literal: true

class Positions::Change
  include Dry::Monads[:result, :do, :try]

  include Dry::Initializer.define -> do
    option :position, Types::Instance(Position)
    option :params, Types::Strict::Hash.schema(
      name?: Types::Strict::String,
      recruiter_id?: Types::Strict::String.optional,
      collaborator_ids?: Types::Strict::Array.of(Types::Strict::String.optional),
      hiring_manager_ids?: Types::Strict::Array.of(Types::Strict::String.optional),
      description?: Types::Strict::String
    ).strict
    option :actor_account, Types::Instance(Account)
  end

  def call
    old_values = {
      name: position.name,
      recruiter_id: position.recruiter_id,
      description: position.description.to_s,
      collaborator_ids: position.collaborators.pluck(:collaborator_id),
      hiring_manager_ids: position.hiring_managers.pluck(:hiring_manager_id)
    }

    position.assign_attributes(params)

    ActiveRecord::Base.transaction do
      yield save_position(position)
      yield add_events(old_values:, position:, actor_account:)
    end

    Success(position.reload)
  end

  private

  def save_position(position)
    result = Try[ActiveRecord::RecordInvalid] do
      position.save!
    end.to_result

    case result
    in Success(_)
      Success()
    in Failure[ActiveRecord::RecordInvalid, e]
      Failure[:position_invalid, position.errors.full_messages.presence || e.to_s]
    end
  end

  def add_events(old_values:, position:, actor_account:)
    yield add_changed_recruiter_events(old_values:, position:, actor_account:)
    yield add_position_changed_events(old_values:, position:, actor_account:)

    Success()
  end

  def add_changed_recruiter_events(old_values:, position:, actor_account:)
    return Success() if old_values[:recruiter_id] == position.recruiter_id

    if old_values[:recruiter_id].present?
      position_recruiter_unassigned_params = {
        actor_account:,
        type: :position_recruiter_unassigned,
        eventable: position,
        changed_from: old_values[:recruiter_id]
      }

      yield Events::Add.new(params: position_recruiter_unassigned_params).call
    end

    return Success() if position.recruiter_id.blank?

    position_recruiter_assigned_params = {
      actor_account:,
      type: :position_recruiter_assigned,
      eventable: position,
      changed_to: position.recruiter_id
    }

    yield Events::Add.new(params: position_recruiter_assigned_params).call

    Success()
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

      yield Events::Add.new(params: position_changed_params).call
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

      yield Events::Add.new(params: position_changed_params).call
    end

    position_collaborator_ids = position.collaborators.pluck(:collaborator_id)
    if old_values[:collaborator_ids].sort != position_collaborator_ids.sort
      position_changed_params = {
        actor_account:,
        type:,
        eventable:,
        changed_field: :collaborators,
        changed_from: old_values[:collaborator_ids],
        changed_to: position_collaborator_ids
      }

      yield Events::Add.new(params: position_changed_params).call
    end

    position_hiring_manager_ids = position.hiring_managers.pluck(:hiring_manager_id)
    if old_values[:hiring_manager_ids].sort != position_hiring_manager_ids.sort
      position_changed_params = {
        actor_account:,
        type:,
        eventable:,
        changed_field: :hiring_managers,
        changed_from: old_values[:hiring_manager_ids],
        changed_to: position_hiring_manager_ids
      }

      yield Events::Add.new(params: position_changed_params).call
    end

    Success()
  end
end
