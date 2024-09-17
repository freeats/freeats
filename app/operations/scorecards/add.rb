# frozen_string_literal: true

class Scorecards::Add
  include Dry::Monads[:result, :try, :do]

  include Dry::Initializer.define -> do
    option :params, Types::Params::Hash.schema(
      title: Types::Params::String,
      interviewer_id: Types::Params::Integer,
      score: Types::Params::String,
      summary?: Types::Params::String,
      position_stage_id: Types::Params::Integer,
      placement_id: Types::Params::Integer
    )
    option :questions_params, Types::Strict::Array.of(
      Types::Strict::Hash.schema(
        question: Types::Params::String,
        answer?: Types::Params::String
      )
    ).optional
    option :actor_account, Types.Instance(Account)
  end

  def call
    scorecard = Scorecard.new(params)

    ActiveRecord::Base.transaction do
      yield save_scorecard(scorecard)
      yield add_questions(scorecard:, questions_params:)
      yield add_event(scorecard:, actor_account:)
    end

    Success(scorecard)
  end

  private

  def save_scorecard(scorecard)
    result = Try[ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique,
                 ActiveRecord::NotNullViolation] do
      scorecard.save!
    end.to_result

    case result
    in Success(_)
      Success(scorecard)
    in Failure[ActiveRecord::RecordInvalid => _e] |
       Failure[ActiveRecord::NotNullViolation => _e]
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

  def add_questions(scorecard:, questions_params:)
    return Success() if questions_params.blank?

    questions_params.each.with_index(1) do |question_params, index|
      question_params[:list_index] = index
      question_params[:scorecard] = scorecard

      yield ScorecardQuestions::Add.new(params: question_params).call
    end

    Success()
  end

  def add_event(scorecard:, actor_account:)
    scorecard_added_params = {
      actor_account:,
      type: :scorecard_added,
      eventable: scorecard
    }

    yield Events::Add.new(params: scorecard_added_params).call

    Success()
  end
end
