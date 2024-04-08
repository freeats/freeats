# frozen_string_literal: true

class Scorecards::Change
  include Dry::Monads[:result, :try, :do]

  # TODO: pass actor_account
  include Dry::Initializer.define -> do
    option :scorecard, Types.Instance(Scorecard)
    option :params, Types::Params::Hash.schema(
      interviewer: Types::Params::String,
      score: Types::Params::String,
      summary?: Types::Params::String
    )
    option :questions_params, Types::Strict::Array.of(
      Types::Strict::Hash.schema(
        id: Types::Params::Integer,
        answer?: Types::Params::String
      )
    ).optional
  end

  def call
    scorecard.assign_attributes(params)

    result = Try[ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique,
                 ActiveRecord::NotNullViolation] do
      ActiveRecord::Base.transaction do
        scorecard.save!

        yield change_questions(questions_params)
      end

      nil
    end.to_result

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

  private

  def change_questions(questions_params)
    return Success() if questions_params.blank?

    questions_params.each do |question_params|
      scorecard_question = scorecard.scorecard_questions.find { _1.id == question_params[:id] }
      answer = question_params[:answer]

      yield ScorecardQuestions::Change.new(scorecard_question:, answer:).call
    end

    Success()
  end
end
