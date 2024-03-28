# frozen_string_literal: true

class ScorecardTemplateQuestions::Add
  include Dry::Monads[:result, :try]

  # TODO: pass actor_account
  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash.schema(
      scorecard_template: Types.Instance(ScorecardTemplate),
      list_index: Types::Integer,
      question: Types::String
    )
  end

  def call
    scorecard_template_question = ScorecardTemplateQuestion.new
    scorecard_template_question.assign_attributes(params)

    result = Try[ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique] do
      scorecard_template_question.save!
    end.to_result

    case result
    in Success(_)
      Success(scorecard_template_question)
    in Failure(ActiveRecord::RecordInvalid => e)
      Failure[:scorecard_template_question_invalid, e]
    in Failure[ActiveRecord::RecordNotUnique => e]
      Failure[:scorecard_template_question_not_unique, e]
    end
  end
end
