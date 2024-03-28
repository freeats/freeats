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
    # old_status = position.status
    # old_change_status_reason = position.change_status_reason

    return Failure[:invalid_status, "Status cannot be changed to draft"] if new_status == "draft"

    position.change_status_reason = new_change_status_reason
    position.status = new_status

    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        position.save!
        # TODO: create events
      end
    end.to_result

    case result
    in Success(_)
      Success(position)
    in Failure[ActiveRecord::RecordInvalid, e]
      Failure[:position_invalid, e]
    end
  end
end
