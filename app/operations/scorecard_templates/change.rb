# frozen_string_literal: true

class ScorecardTemplates::Change < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :params, Types::Strict::Hash.schema(
    title?: Types::String
  )
  option :questions_params, Types::Strict::Array.of(
    Types::Strict::Hash.schema(question: Types::String)
  ).optional
  option :scorecard_template, Types.Instance(ScorecardTemplate)
  option :actor_account, Types.Instance(Account)

  def call
    old_values = {
      title: scorecard_template.title,
      questions_params: existing_questions_params(scorecard_template)
    }

    scorecard_template.assign_attributes(params)

    ActiveRecord::Base.transaction do
      yield save_scorecard_template(scorecard_template)
      yield change_scorecard_template_questions(scorecard_template:, questions_params:)
      yield add_event(old_values:, scorecard_template:, actor_account:)
    end

    Success(scorecard_template)
  end

  private

  def save_scorecard_template(scorecard_template)
    scorecard_template.save!

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:scorecard_template_invalid, scorecard_template.errors.full_messages.presence || e.to_s]
  rescue ActiveRecord::RecordNotUnique => e
    Failure[:scorecard_template_not_unique,
            scorecard_template.errors.full_messages.presence || e.to_s]
  end

  def change_scorecard_template_questions(scorecard_template:, questions_params:)
    # The scorecard_template is always edited with questions, which means that we should destroy
    # the old question in any case, even if the new questions are empty
    scorecard_template.scorecard_template_questions.destroy_all

    questions_params.each.with_index(1) do |question_params, index|
      yield ScorecardTemplateQuestions::Add.new(
        params: { scorecard_template:, list_index: index, **question_params }
      ).call
    end

    scorecard_template.reload

    Success()
  end

  def add_event(old_values:, scorecard_template:, actor_account:)
    return Success() unless scorecard_template_changed?(old_values:, scorecard_template:)

    scorecard_template_changed_params = {
      actor_account:,
      type: :scorecard_template_changed,
      eventable: scorecard_template
    }

    yield Events::Add.new(params: scorecard_template_changed_params).call

    Success()
  end

  def scorecard_template_changed?(old_values:, scorecard_template:)
    old_values[:title] != scorecard_template.title ||
      old_values[:questions_params] != existing_questions_params(scorecard_template)
  end

  def existing_questions_params(scorecard_template)
    scorecard_template.scorecard_template_questions.map do |question|
      { question: question.question, index: question.list_index }
    end
  end
end
