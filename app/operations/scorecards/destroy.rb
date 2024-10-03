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

      yield Events::Add.new(
        params:
          {
            type: :scorecard_removed,
            eventable: placement,
            changed_from: scorecard.title,
            actor_account:
          }
      ).call
    end

    Success(candidate_id)
  rescue ActiveRecord::RecordNotDestroyed => e
    Failure[:scorecard_not_destroyed, e.record.errors]
  end
end
