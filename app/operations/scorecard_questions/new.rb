# frozen_string_literal: true

class ScorecardQuestions::New < ApplicationOperation
  include Dry::Monads[:result]

  option :params, Types::Strict::Hash.schema(
    scorecard: Types.Instance(Scorecard),
    list_index: Types::Integer,
    question: Types::String
  )

  def call
    scorecard_question = ScorecardQuestion.new(params)

    Success(scorecard_question)
  end
end
