# frozen_string_literal: true

class ScorecardTemplates::New
  include Dry::Monads[:result]

  include Dry::Initializer.define -> do
    option :position_stage_id, Types::Params::Integer
  end

  def call
    position_stage = PositionStage.find(position_stage_id)
    params = {
      position_stage:,
      title: "#{position_stage.name} stage scorecard template"
    }

    scorecard = ScorecardTemplate.new(params)

    Success(scorecard)
  end
end
