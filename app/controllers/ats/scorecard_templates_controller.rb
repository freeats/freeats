# frozen_string_literal: true

class ATS::ScorecardTemplatesController < AuthorizedController
  include Dry::Monads[:result]

  layout "ats/application"

  before_action :set_scorecard_template, only: %i[show edit update destroy]
  before_action :authorize!, only: %i[new create]
  before_action -> { authorize!(@scorecard_template) },
                only: %i[show edit update destroy]

  def show; end

  def new
    case ScorecardTemplates::New.new(position_stage_id: params[:position_stage_id]).call
    in Success(scorecard_template)
      @scorecard_template = scorecard_template
    end
  end

  def edit; end

  def create
    case ScorecardTemplates::Add.new(
      params: scorecard_template_params,
      questions_params:,
      actor_account: current_account
    ).call
    in Success(scorecard_template)
      redirect_to ats_scorecard_template_path(scorecard_template)
    in Failure[:scorecard_template_invalid, _e] |
       Failure[:scorecard_template_not_unique, _e] |
       Failure[:scorecard_template_question_invalid, _e] |
       Failure[:scorecard_template_question_not_unique, _e]
      render_error _e, status: :unprocessable_entity
    end
  end

  def update
    case ScorecardTemplates::Change.new(
      scorecard_template: @scorecard_template,
      params: scorecard_template_params,
      questions_params:,
      actor_account: current_account
    ).call
    in Success(scorecard_template)
      redirect_to ats_scorecard_template_path(scorecard_template)
    in Failure[:scorecard_template_invalid, _e] |
       Failure[:scorecard_template_not_unique, _e] |
       Failure[:scorecard_template_question_invalid, _e] |
       Failure[:scorecard_template_question_not_unique, _e]
      render_error _e, status: :unprocessable_entity
    end
  end

  def destroy
    case ScorecardTemplates::Destroy.new(
      scorecard_template: @scorecard_template,
      actor_account: current_account
    ).call
    in Success(position)
      redirect_to ats_position_path(position)
    in Failure[:scorecard_template_not_destroyed, _error] | Failure[:event_invalid, _error]
      render_error _error, status: :unprocessable_entity
    end
  end

  private

  def scorecard_template_params
    params
      .require(:scorecard_template)
      .permit(
        :title,
        :position_stage_id
      )
      .to_h
      .deep_symbolize_keys
  end

  def questions_params
    params
      .require(:scorecard_template)
      .permit(scorecard_template_questions_attributes: [:question])
      .[](:scorecard_template_questions_attributes)
      .to_h
      .deep_symbolize_keys
      .values
      .reject { |hash| hash[:question].blank? }
  end

  def set_scorecard_template
    @scorecard_template = ScorecardTemplate.find(params[:id])
  end
end
