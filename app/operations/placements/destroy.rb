# frozen_string_literal: true

class Placements::Destroy < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :placement, Types::Instance(Placement)
  option :actor_account, Types::Instance(Account)

  def call
    ActiveRecord::Base.transaction do
      yield add_event(placement:, actor_account:)
      yield destroy_placement(placement)
    end

    Success(placement)
  end

  private

  def destroy_placement(placement)
    placement.destroy!

    Success()
  rescue ActiveRecord::RecordNotDestroyed => e
    Failure[:placement_not_destroyed, e.record.errors]
  end

  def add_event(placement:, actor_account:)
    params = {
      actor_account:,
      type: :placement_removed,
      eventable: placement.candidate,
      properties: {
        position_id: placement.position_id,
        placement_id: placement.id,
        placement_stage: placement.stage,
        placement_status: placement.status,
        added_actor_account_id: placement.added_event.actor_account_id,
        added_at: placement.added_event.performed_at
      }
    }

    yield Events::Add.new(params:).call

    Success()
  end
end
