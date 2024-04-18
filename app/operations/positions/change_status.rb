# frozen_string_literal: true

class Positions::ChangeStatus
  include Dry::Monads[:result, :do, :try]

  include Dry::Initializer.define -> do
    option :position, Types::Instance(Position)
    option :actor_account, Types::Instance(Account)
    option :new_status, Types::Strict::String
    option :new_change_status_reason, Types::Strict::String
    option :comment, Types::Strict::String
  end

  def call
    old_status = position.status

    return Success(position) if old_status == new_status
    return Failure[:invalid_status, "Status cannot be changed to draft"] if new_status == "draft"

    position.change_status_reason = new_change_status_reason
    position.status = new_status

    position_changed_params = {
      actor_account:,
      type: :position_changed,
      eventable: position,
      changed_field: :status,
      changed_from: old_status,
      changed_to: new_status,
      properties: {
        comment:,
        change_status_reason: new_change_status_reason
      }
    }

    ActiveRecord::Base.transaction do
      yield save_position(position)
      yield Events::Add.new(params: position_changed_params).call
    end

    Success(position)
  end

  private

  def save_position(position)
    result = Try[ActiveRecord::RecordInvalid] do
      position.save!
    end.to_result

    case result
    in Success(_)
      Success()
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:position_invalid, position.errors.full_messages.presence || e.to_s]
    end
  end
end
