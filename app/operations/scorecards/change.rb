# frozen_string_literal: true

class Scorecards::Change < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :params, Types::Params::Hash.schema(
    interviewer_id: Types::Params::Integer,
    score: Types::Params::String,
    summary?: Types::Params::String
  )
  option :questions_params, Types::Strict::Array.of(
    Types::Strict::Hash.schema(
      id: Types::Params::Integer,
      answer?: Types::Params::String
    )
  ).optional
  option :scorecard, Types::Instance(Scorecard)
  option :actor_account, Types::Instance(Account).optional, optional: true

  def call
    old_values = {
      interviewer: scorecard.interviewer,
      score: scorecard.score,
      summary: scorecard.summary.body&.to_plain_text || "",
      questions_params: existing_questions_params(scorecard)
    }

    scorecard.assign_attributes(params)

    ActiveRecord::Base.transaction do
      yield save_scorecard(scorecard)
      yield change_questions(scorecard:, questions_params:)
      add_event(scorecard:, actor_account:) if scorecard_changed?(old_values:, scorecard:)
    end

    Success(scorecard)
  end

  private

  def save_scorecard(scorecard)
    scorecard.save!

    Success()
  rescue ActiveRecord::RecordInvalid, ActiveRecord::NotNullViolation => e
    Failure[:scorecard_invalid, scorecard.errors.full_messages.presence || e.to_s]
  rescue ActiveRecord::RecordNotUnique => e
    Failure[:scorecard_not_unique, scorecard.errors.full_messages.presence || e.to_s]
  end

  def change_questions(scorecard:, questions_params:)
    return Success() if questions_params.blank?

    questions_params.each do |question_params|
      scorecard_question = scorecard.scorecard_questions.find { _1.id == question_params[:id] }
      answer = question_params[:answer]

      yield ScorecardQuestions::Change.new(scorecard_question:, answer:).call
    end

    Success()
  end

  def add_event(scorecard:, actor_account:)
    scorecard_changed_params = {
      actor_account:,
      type: :scorecard_changed,
      eventable: scorecard
    }
    Event.create!(scorecard_changed_params)
  end

  def scorecard_changed?(old_values:, scorecard:)
    old_values[:interviewer] != scorecard.interviewer ||
      old_values[:score] != scorecard.score ||
      old_values[:summary] != scorecard.summary.body.to_plain_text ||
      old_values[:questions_params] != existing_questions_params(scorecard)
  end

  def existing_questions_params(scorecard)
    scorecard.scorecard_questions.map do |question|
      { id: question.id, answer: question.answer.body.to_s }
    end
  end
end
