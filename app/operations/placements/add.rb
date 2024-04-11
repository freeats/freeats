# frozen_string_literal: true

class Placements::Add
  include Dry::Monads[:result, :try]

  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash.schema(
      candidate_id: Types::Coercible::Integer,
      position_id: Types::Coercible::Integer
    )
    option :create_duplicate_placement, Types::Strict::Bool, default: -> { false }
    option :actor_account, Types::Instance(Account)
  end

  def call
    placement = Placement.new(
      candidate_id: params[:candidate_id],
      position_id: params[:position_id],
      position_stage_id:
        PositionStage
        .select(:id)
        .find_by(list_index: 1, position_id: params[:position_id])
        .id
    )

    unless create_duplicate_placement
      already_existed_placement =
        Placement
        .where(candidate_id: params[:candidate_id], position_id: params[:position_id])
        .order(:created_at)
        .last

      if already_existed_placement.present?
        return Failure[:placement_already_exists, already_existed_placement]
      end
    end

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
