# frozen_string_literal: true

class ScorecardQuestions::Add
  include Dry::Monads[:result, :try]

  # TODO: pass actor_account
  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash.schema(
      scorecard: Types.Instance(Scorecard),
      list_index: Types::Integer,
      question: Types::String
    )
  end

  def call
    scorecard_question = ScorecardQuestion.new
    scorecard_question.assign_attributes(params)

    result = Try[ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique] do
      scorecard_question.save!
    end.to_result

    case result
    in Success(_)
      Success(scorecard_question)
    in Failure(ActiveRecord::RecordInvalid => e)
      Failure[:scorecard_question_invalid, e]
    in Failure[ActiveRecord::RecordNotUnique => e]
      Failure[:scorecard_question_not_unique, e]
    end
  end
end
