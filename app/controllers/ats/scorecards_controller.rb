# frozen_string_literal: true

class ATS::ScorecardsController < AuthorizedController
  include Dry::Monads[:result]

  layout "ats/application"

  before_action :set_scorecard, only: %i[show edit update destroy]
  before_action -> { authorize!(@scorecard) },
                only: %i[show edit update destroy]
  before_action :compose_interviewers, only: %i[new edit]

  def show; end

  def new
    scorecard_template = PositionStage.find(params[:position_stage_id]).scorecard_template
    authorize!(scorecard_template, to: :new?, with: ATS::ScorecardPolicy)
    placement = Placement.find(params[:placement_id])

    case Scorecards::New.new(scorecard_template:, placement:).call
    in Success(scorecard)
      @scorecard = scorecard
    end
  end

  def edit; end

  def create
    scorecard_template = PositionStage.find(scorecard_params[:position_stage_id]).scorecard_template
    authorize!(scorecard_template, to: :create?, with: ATS::ScorecardPolicy)
    questions_params = scorecard_params.delete(:scorecard_questions_attributes)
    questions_params = questions_params.values if questions_params.present?

    case Scorecards::Add.new(
      params: scorecard_params,
      questions_params:,
      actor_account: current_account
    ).call
    in Success(scorecard)
      redirect_to ats_scorecard_path(scorecard)
    in Failure[:scorecard_invalid, _error] |
       Failure[:scorecard_not_unique, _error] |
       Failure[:scorecard_question_invalid, _error] |
       Failure[:scorecard_question_not_unique, _error]
      render_error _error, status: :unprocessable_entity
    end
  end

  def update
    questions_params = scorecard_params.delete(:scorecard_questions_attributes)
    questions_params = questions_params.values if questions_params.present?

    case Scorecards::Change.new(
      scorecard: @scorecard,
      params: scorecard_params,
      questions_params:,
      actor_account: current_account
    ).call
    in Success(scorecard)
      redirect_to ats_scorecard_path(scorecard)
    in Failure[:scorecard_invalid, _error] |
       Failure[:scorecard_not_unique, _error] |
       Failure[:scorecard_question_invalid, _error] |
       Failure[:scorecard_question_not_unique, _error]
      render_error _error, status: :unprocessable_entity
    end
  end

  def destroy
    case Scorecards::Destroy.new(
      scorecard: @scorecard,
      actor_account: current_account
    ).call
    in Success(candidate_id)
      redirect_to tab_ats_candidate_path(candidate_id, :scorecards)
    in Failure[:scorecard_not_destroyed, _error] | Failure[:event_invalid, _error]
      render_error _error, status: :unprocessable_entity
    end
  end

  private

  def compose_interviewers
    active_members = Member.active.includes(:account).to_a

    position_members = []
    if @scorecard.present?
      position = @scorecard.placement.position
      position_member_ids =
        [position.recruiter_id,
         *position.collaborators.ids,
         *position.hiring_managers.ids,
         *position.interviewers.ids].uniq
      position_members = Member.where(id: position_member_ids).includes(:account).to_a
    end

    @interviewers = (position_members | active_members).map do |member|
      { text: member.name, value: member.id, selected: member.id == @scorecard&.interviewer_id }
    end
  end

  def set_scorecard
    @scorecard =
      Scorecard
      .includes(
        :scorecard_questions,
        :position_stage,
        interviewer: :account,
        placement: { position: %i[collaborators hiring_managers interviewers] }
      )
      .find(params[:id])
  end

  def scorecard_params
    @scorecard_params ||=
      params
      .require(:scorecard)
      .permit(
        :title,
        :interviewer_id,
        :score,
        :summary,
        :position_stage_id,
        :placement_id,
        scorecard_questions_attributes: %i[id question answer]
      )
      .to_h
      .deep_symbolize_keys
  end
end
