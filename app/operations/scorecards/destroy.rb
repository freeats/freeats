# frozen_string_literal: true

class Scorecards::Destroy < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :scorecard, Types.Instance(Scorecard)
  option :actor_account, Types.Instance(Account)

  def call
    placement = scorecard.placement
    candidate_id = placement.candidate_id

    ActiveRecord::Base.transaction do
      scorecard.destroy!

      yield add_event(placement:, changed_from: scorecard.title)
    end

    Success(candidate_id)
  rescue ActiveRecord::RecordNotDestroyed => e
    Failure[:scorecard_not_destroyed, e.record.errors]
  end

  private

  def add_event(placement:, changed_from:)
    Event.create!(
      type: :scorecard_removed,
      eventable: placement,
      changed_from:,
      performed_at: Time.zone.now,
      actor_account:
    )

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:event_invalid, e.to_s]
  end
end
