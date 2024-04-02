# frozen_string_literal: true

class ScorecardTemplates::Change
  include Dry::Monads[:result, :try, :do]

  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash.schema(
      visible_to_interviewer?: Types::Params::Bool,
      title?: Types::String
    )
    option :questions_params, Types::Strict::Array.of(
      Types::Strict::Hash.schema(question: Types::String)
    ).optional
    option :scorecard_template, Types.Instance(ScorecardTemplate)
  end

  def call
    result = Try[ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique] do
      ActiveRecord::Base.transaction do
        scorecard_template.update!(params)

        # The scorecard_template is always edited with questions, which means that we should destroy
        # the old question in any case, even if the new questions are empty
        scorecard_template.scorecard_template_questions.destroy_all

        questions_params.each.with_index(1) do |question_params, index|
          yield ScorecardTemplateQuestions::Add.new(
            params: { scorecard_template:, list_index: index, **question_params }
          ).call
        end

        scorecard_template
      end
    end.to_result

    case result
    in Success(_)
      Success(scorecard_template)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:scorecard_template_invalid,
              scorecard_template.errors.full_messages.presence || e.to_s]
    in Failure[ActiveRecord::RecordNotUnique => e]
      Failure[:scorecard_template_not_unique,
              scorecard_template.errors.full_messages.presence || e.to_s]
    in Failure[:scorecard_template_question_invalid, _e] |
       Failure[:scorecard_template_question_not_unique, _e]
      result
    end
  end
end
