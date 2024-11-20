# frozen_string_literal: true

class Placements::Add < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :params, Types::Strict::Hash.schema(
    candidate_id: Types::Coercible::Integer,
    position_id: Types::Coercible::Integer,
    suggestion_disqualify_reason?: Types::Strict::String.optional
  )
  option :create_duplicate_placement, Types::Strict::Bool, default: -> { false }
  option :actor_account, Types::Instance(Account).optional, optional: true
  option :applied, Types::Strict::Bool, default: -> { false }

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

    ActiveRecord::Base.transaction do
      yield save_placement(placement)
      add_event(placement:, actor_account:)

      if (reason = params[:suggestion_disqualify_reason]).present?
        yield Placements::ChangeStatus.new(
          new_status: reason,
          placement:,
          actor_account:
        ).call
      end
    end

    Success(placement.reload)
  end

  private

  def save_placement(placement)
    placement.save!

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:placement_invalid, placement.errors.full_messages.presence || e.to_s]
  rescue ActiveRecord::RecordNotUnique => e
    Failure[:placement_not_unique, placement.errors.full_messages.presence || e.to_s]
  end

  def add_event(placement:, actor_account:)
    Event.create!(
      actor_account:,
      type: :placement_added,
      eventable: placement,
      properties: (applied ? { applied: } : {})
    )
  end
end
