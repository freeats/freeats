# frozen_string_literal: true

class ATS::ScorecardsController < ApplicationController
  include Dry::Monads[:result]

  layout "ats/application"

  before_action :set_scorecard, only: %i[show]

  def show; end
  def new
    scorecard_template = PositionStage.find(params[:position_stage_id]).scorecard_template
    placement = Placement.find(params[:placement_id])

    case Scorecards::New.new(scorecard_template:, placement:).call
    in Success(scorecard)
      @scorecard = scorecard
    end
  end

  def create; end

  private

  def set_scorecard
    @scorecard = Scorecard.find(params[:id])
  end
end
