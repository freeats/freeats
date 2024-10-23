# frozen_string_literal: true

class Scorecards::New < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :scorecard_template, Types.Instance(ScorecardTemplate)
  option :placement, Types.Instance(Placement)

  def call
    params = { placement: }
    params[:position_stage_id] = scorecard_template.position_stage_id
    params[:title] = "#{scorecard_template.title} scorecard"

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
