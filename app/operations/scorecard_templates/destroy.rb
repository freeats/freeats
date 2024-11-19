# frozen_string_literal: true

class ScorecardTemplates::Destroy < ApplicationOperation
  include Dry::Monads[:result]

  option :scorecard_template, Types.Instance(ScorecardTemplate)
  option :actor_account, Types::Instance(Account).optional, optional: true

  def call
    position_stage = scorecard_template.position_stage
    position_id = position_stage.position_id

    ActiveRecord::Base.transaction do
      scorecard_template.destroy!

      add_event(position_stage:, actor_account:)
    end

    Success(position_id)
  rescue ActiveRecord::RecordNotDestroyed => e
    Failure[:scorecard_template_not_destroyed, e.record.errors]
  end

  def add_event(position_stage:, actor_account:)
    Event.create!(
      type: :scorecard_template_removed,
      eventable: position_stage,
      actor_account:
    )
  end
end
