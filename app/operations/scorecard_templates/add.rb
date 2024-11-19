# frozen_string_literal: true

class ScorecardTemplates::Add < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :params, Types::Params::Hash.schema(
    position_stage_id: Types::Params::Integer,
    title: Types::Params::String
  )
  option :questions_params, Types::Strict::Array.of(
    Types::Strict::Hash.schema(question: Types::Params::String)
  ).optional
  option :actor_account, Types.Instance(Account)

  def call
    scorecard_template = ScorecardTemplate.new(params)

    ActiveRecord::Base.transaction do
      yield save_scorecard_template(scorecard_template)
      yield add_scorecard_template_questions(scorecard_template:, questions_params:)
      add_event(scorecard_template:, actor_account:)
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

  def add_scorecard_template_questions(scorecard_template:, questions_params:)
    questions_params.each.with_index(1) do |question_params, index|
      yield ScorecardTemplateQuestions::Add.new(
        params: { scorecard_template:, list_index: index, **question_params }
      ).call
    end

    Success()
  end

  def add_event(scorecard_template:, actor_account:)
    scorecard_template_added_params = {
      actor_account:,
      type: :scorecard_template_added,
      eventable: scorecard_template
    }
    Event.create!(scorecard_template_added_params)
  end
end
