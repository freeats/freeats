# frozen_string_literal: true

class ScorecardTemplates::Add
  include Dry::Monads[:result, :try, :do]

  include Dry::Initializer.define -> do
    option :params, Types::Params::Hash.schema(
      position_stage_id: Types::Params::Integer,
      visible_to_interviewer: Types::Params::Bool,
      title: Types::Params::String
    )
    option :questions_params, Types::Strict::Array.of(
      Types::Strict::Hash.schema(question: Types::Params::String)
    ).optional
    option :actor_account, Types.Instance(Account)
  end

  def call
    scorecard_template = ScorecardTemplate.new(params)

    ActiveRecord::Base.transaction do
      yield save_scorecard_template(scorecard_template)
      yield add_scorecard_template_questions(scorecard_template:, questions_params:)
      yield add_event(scorecard_template:, actor_account:)
    end

    Success(scorecard_template)
  end

  private

  def save_scorecard_template(scorecard_template)
    result = Try[ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique] do
      scorecard_template.save!
    end.to_result

    case result
    in Success(_)
      Success(scorecard_template)
    in Failure(ActiveRecord::RecordInvalid => e)
      Failure[:scorecard_template_invalid,
              scorecard_template.errors.full_messages.presence || e.to_s]
    in Failure[ActiveRecord::RecordNotUnique => e]
      Failure[:scorecard_template_not_unique,
              scorecard_template.errors.full_messages.presence || e.to_s]
    end
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

    yield Events::Add.new(params: scorecard_template_added_params).call

    Success()
  end
end
