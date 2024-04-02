# frozen_string_literal: true

class ATS::ScorecardTemplatesController < ApplicationController
  include Dry::Monads[:result]

  layout "ats/application"

  before_action :set_scorecard_template, only: %i[show edit update]

  def show; end

  def edit; end

  def create
    position_stage = PositionStage.find(params[:position_stage_id])
    case ScorecardTemplates::Add.new(position_stage:).call
    in Success(scorecard_template)
      redirect_to ats_scorecard_template_path(scorecard_template)
    in Failure[:scorecard_template_invalid, e]
      render_error e
    end
  end

  def update
    case ScorecardTemplates::Change.new(
      scorecard_template: @scorecard_template,
      params: scorecard_template_params,
      questions_params:
    ).call
    in Success(scorecard_template)
      redirect_to ats_scorecard_template_path(scorecard_template)
    in Failure[:scorecard_template_invalid, e]
      render_error e
    end
  end

  private

  def scorecard_template_params
    params
      .require(:scorecard_template)
      .permit(
        :title,
        :visible_to_interviewer,
        scorecard_template_questions_attributes: [:question]
      )
      .to_h
      .deep_symbolize_keys
  end

  def questions_params
    scorecard_template_params
    .[](:scorecard_template_questions_attributes)
      .to_h
      .filter_map do |_index, hash|
      next if hash[:question].blank?

      hash
    end
  end

  def set_scorecard_template
    @scorecard_template = ScorecardTemplate.find(params[:id])
  end
end
