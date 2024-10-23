# frozen_string_literal: true

class ScorecardTemplates::New < ApplicationOperation
  include Dry::Monads[:result]

  option :position_stage_id, Types::Params::Integer

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
