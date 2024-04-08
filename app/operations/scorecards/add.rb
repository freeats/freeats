# frozen_string_literal: true

class Scorecards::Add
  include Dry::Monads[:result, :try, :do]

  # TODO: pass actor_account
  include Dry::Initializer.define -> do
    option :params, Types::Params::Hash.schema(
      title: Types::Params::String,
      interviewer: Types::Params::String,
      score: Types::Params::String,
      summary?: Types::Params::String,
      position_stage_id: Types::Params::Integer,
      placement_id: Types::Params::Integer,
      visible_to_interviewer: Types::Params::Bool
    )
    option :questions_params, Types::Strict::Array.of(
      Types::Strict::Hash.schema(
        question: Types::Params::String,
        answer?: Types::Params::String
      )
    ).optional
  end

  def call
    scorecard = Scorecard.new(params)

    result = Try[ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique,
                 ActiveRecord::NotNullViolation] do
      ActiveRecord::Base.transaction do
        scorecard.save!

        yield add_questions(scorecard, questions_params)
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

  def add_questions(scorecard, questions_params)
    return Success() if questions_params.blank?

    questions_params.each.with_index(1) do |question_params, index|
      question_params[:list_index] = index
      question_params[:scorecard] = scorecard

      yield ScorecardQuestions::Add.new(params: question_params).call
    end

    Success()
  end
end
