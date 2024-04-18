# frozen_string_literal: true

class Placements::ChangeStatus
  include Dry::Monads[:result, :do, :try]

  include Dry::Initializer.define -> do
    option :new_status, Types::Strict::String
    option :placement, Types::Instance(Placement)
    option :actor_account, Types::Instance(Account)
  end

  def call
    old_status = placement.status

    return Success(placement) if old_status == new_status

    placement.status = new_status

    placement_changed_params = {
      actor_account:,
      type: :placement_changed,
      eventable: placement,
      changed_field: :status,
      changed_from: old_status,
      changed_to: new_status
    }

    ActiveRecord::Base.transaction do
      yield save_placement(placement)
      yield Events::Add.new(params: placement_changed_params).call
    end

    Success(placement)
  end

  private

  def save_placement(placement)
    result = Try[ActiveRecord::RecordInvalid] do
      placement.save!
    end.to_result

    case result
    in Success(_)
      Success()
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:placement_invalid, placement.errors.full_messages.presence || e.to_s]
    end
  end
end
