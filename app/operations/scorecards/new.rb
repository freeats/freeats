# frozen_string_literal: true

class Scorecards::New
  include Dry::Monads[:result, :do]

  # TODO: pass actor_account
  include Dry::Initializer.define -> do
    option :scorecard_template, Types.Instance(ScorecardTemplate)
    option :placement, Types.Instance(Placement)
  end

  def call
    params = { placement: }
    params[:position_stage_id] = scorecard_template.position_stage_id
    params[:title] = scorecard_template.title
    params[:visible_to_interviewer] = scorecard_template.visible_to_interviewer

    scorecard = Scorecard.new(params)

    scorecard_template.scorecard_template_questions.each do |stq|
      question_params = {
        scorecard:,
        question: stq.question,
        list_index: stq.list_index
      }

      scorecard_question = yield ScorecardQuestions::New.new(params: question_params).call
      scorecard.scorecard_questions << scorecard_question
    end

    Success(scorecard)
  end
end
