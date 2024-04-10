# frozen_string_literal: true

class ScorecardTemplates::Add
  include Dry::Monads[:result, :try, :do]

  include Dry::Initializer.define -> do
    option :position_stage, Types.Instance(PositionStage)
    option :actor_account, Types.Instance(Account)
  end

  def call
    params = {
      position_stage:,
      title: "#{position_stage.name} stage scorecard template"
    }
    scorecard_template = ScorecardTemplate.new
    scorecard_template.assign_attributes(params)

    ActiveRecord::Base.transaction do
      yield save_scorecard_template(scorecard_template)
      yield add_event(scorecard_template:, actor_account:)
    end

    Success(scorecard_template)
  end

  private

  def save_scorecard_template(scorecard_template)
    result = Try[ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique] do
      scorecard_template.save!
    end.to_result

    case result
    in Success(_)
      Success(scorecard_template)
    in Failure(ActiveRecord::RecordInvalid => e)
      Failure[:scorecard_template_invalid,
              scorecard_template.errors.full_messages.presence || e.to_s]
    in Failure[ActiveRecord::RecordNotUnique => e]
      Failure[:scorecard_template_not_unique,
              scorecard_template.errors.full_messages.presence || e.to_s]
    end
  end

  def add_event(scorecard_template:, actor_account:)
    scorecard_template_added_params = {
      actor_account:,
      type: :scorecard_template_added,
      eventable: scorecard_template
    }

    yield Events::Add.new(params: scorecard_template_added_params).call

    Success()
  end
end
