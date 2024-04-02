# frozen_string_literal: true

class ScorecardTemplates::Add
  include Dry::Monads[:result, :try]

  # TODO: pass actor_account
  include Dry::Initializer.define -> do
    option :position_stage, Types.Instance(PositionStage)
  end

  def call
    params = {
      position_stage:,
      title: "#{position_stage.name.capitalize} stage scorecard template"
    }
    scorecard_template = ScorecardTemplate.new
    scorecard_template.assign_attributes(params)

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
end
