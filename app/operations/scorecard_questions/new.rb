# frozen_string_literal: true

class ScorecardQuestions::New
  include Dry::Monads[:result]

  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash.schema(
      scorecard: Types.Instance(Scorecard),
      list_index: Types::Integer,
      question: Types::String
    )
  end

  def call
    scorecard_question = ScorecardQuestion.new(params)

    Success(scorecard_question)
  end
end
