# frozen_string_literal: true

class Positions::Add
  include Dry::Monads[:result, :do, :try]

  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash.schema(
      name: Types::Strict::String
    )
    option :actor_account, Types::Instance(Account)
  end

  def call
    auto_assigned_params = {
      recruiter_id: actor_account.member.id
    }
    position = Position.new(params.merge(auto_assigned_params))

    ActiveRecord::Base.transaction do
      yield save_position(position)
      yield add_default_stages(position, actor_account:)
      yield add_events(position:, actor_account:)
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
      Success(position)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:position_invalid, position.errors.full_messages.presence || e.to_s]
    end
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

    yield Events::Add.new(params: position_added_params).call

    position_changed_params = {
      actor_account:,
      type: :position_changed,
      eventable: position,
      changed_field: :name,
      changed_to: position.name
    }

    yield Events::Add.new(params: position_changed_params).call

    position_recruiter_assigned_params = {
      actor_account:,
      type: :position_recruiter_assigned,
      eventable: position,
      changed_to: position.recruiter_id
    }

    yield Events::Add.new(params: position_recruiter_assigned_params).call

    Success()
  end
end
