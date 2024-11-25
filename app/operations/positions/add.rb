# frozen_string_literal: true

class Positions::Add < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :params, Types::Strict::Hash.schema(
    name: Types::Strict::String,
    location_id?: Types::Coercible::Integer.optional.fallback(nil)
  )
  option :actor_account, Types::Instance(Account)

  def call
    auto_assigned_params = {
      recruiter_id: actor_account.member.id
    }
    position = Position.new(params.merge(auto_assigned_params))

    ActiveRecord::Base.transaction do
      yield save_position(position)
      yield add_default_stages(position, actor_account:)
      add_events(position:, actor_account:)
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

  def add_default_stages(position, actor_account:)
    Position::DEFAULT_STAGES.each.with_index(1) do |name, index|
      params = { position:, name:, list_index: index }
      yield PositionStages::Add.new(params:, actor_account:).call
    end

    Success()
  end

  def add_events(position:, actor_account:)
    position_added_params = {
      actor_account:,
      type: :position_added,
      eventable: position
    }

    Event.create!(position_added_params)

    position_changed_params = {
      actor_account:,
      type: :position_changed,
      eventable: position,
      changed_field: :name,
      changed_to: position.name
    }

    Event.create!(position_changed_params)

    position_recruiter_assigned_params = {
      actor_account:,
      type: :position_recruiter_assigned,
      eventable: position,
      changed_to: position.recruiter_id
    }

    Event.create!(position_recruiter_assigned_params)

    return if params[:location_id].blank?

    Event.create_changed_event_if_value_changed(
      eventable: position,
      changed_field: "location",
      old_value: nil,
      new_value: position.location.short_name,
      actor_account:
    )
  end
end
