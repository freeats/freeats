# frozen_string_literal: true

class Scorecards::Add
  include Dry::Monads[:result, :try, :do]

  # TODO: pass actor_account
  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash.schema(
      placement: Types.Instance(Placement),
      score: Types::String.enum(*Scorecard.scores.keys),
      interviewer: Types::String
    )
    option :scorecard_template, Types.Instance(ScorecardTemplate)
  end

  def call
    params[:position_stage_id] = scorecard_template.position_stage_id
    params[:title] = scorecard_template.title
    params[:visible_to_interviewer] = scorecard_template.visible_to_interviewer

    scorecard = Scorecard.new
    scorecard.assign_attributes(params)

    result = Try[ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique,
                 ActiveRecord::NotNullViolation] do
      ActiveRecord::Base.transaction do
        scorecard.save!

        scorecard_template.scorecard_template_questions.each do |stq|
          params = {
            scorecard:,
            question: stq.question,
            list_index: stq.list_index
          }

          (yield ScorecardQuestions::Add.new(params:).call)
        end
      end
    end

    result = result.to_result

    case result
    in Success(_)
      Success(scorecard)
    in Failure(ActiveRecord::RecordInvalid => _e) |
       Failure(ActiveRecord::NotNullViolation => _e)
      Failure[:scorecard_invalid,
              scorecard.errors.full_messages.presence || _e.to_s]
    in Failure[ActiveRecord::RecordNotUnique => e]
      Failure[:scorecard_not_unique,
              scorecard.errors.full_messages.presence || e.to_s]
    in Failure[:scorecard_question_invalid, _e] |
       Failure[:scorecard_question_not_unique, _e]
      result
    end
  end
end
