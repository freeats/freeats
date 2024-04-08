# frozen_string_literal: true

class ScorecardQuestions::Change
  include Dry::Monads[:result, :try]

  include Dry::Initializer.define -> do
    option :scorecard_question, Types.Instance(ScorecardQuestion)
    option :answer, Types::Params::String
  end

  def call
    scorecard_question.answer = answer

    result = Try[ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique] do
      scorecard_question.save!
    end.to_result

    case result
    in Success(_)
      Success(scorecard_question)
    in Failure(ActiveRecord::RecordInvalid => e)
      Failure[:scorecard_question_invalid,
              scorecard_question.errors.full_messages.presence || e.to_s]
    in Failure[ActiveRecord::RecordNotUnique => e]
      Failure[:scorecard_question_not_unique,
              scorecard_question.errors.full_messages.presence || e.to_s]
    end
  end
end
