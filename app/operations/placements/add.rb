# frozen_string_literal: true

class Placements::Add
  include Dry::Monads[:result, :try]

  include Dry::Initializer.define -> do
    option :candidate_id, Types::Coercible::Integer
    option :position_id, Types::Coercible::Integer
    option :actor_account, Types::Instance(Account)
  end

  def call
    placement = Placement.new(
      candidate_id:,
      position_id:,
      position_stage_id: PositionStage.select(:id).find_by(list_index: 1, position_id:).id
    )

    result = Try[ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique] do
      placement.save!

      # TODO: add events
    end.to_result

    case result
    in Success(_)
      Success(placement)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:placement_invalid, placement.errors.full_messages.presence || e.to_s]
    in Failure[ActiveRecord::RecordNotUnique => e]
      Failure[:placement_not_unique, placement.errors.full_messages.presence || e.to_s]
    end
  end
end
