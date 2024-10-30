# frozen_string_literal: true

class Positions::Order < ApplicationOperation
  include Dry::Monads[:result]

  MULTIPLIER = { "open" => 10, "on_hold" => 1, "draft" => 0.1, "closed" => 0 }.freeze

  option :positions, Types::Strict::Array.of(Types::Instance(Position))
  option :query, Types::Strict::String

  def call
    positions_with_score = positions.map do |position|
      basic_score = SelectComponent::Score.new(text: position.name, query:).call.value!

      { position:, score: basic_score * MULTIPLIER[position.status] }
    end

    Success(positions_with_score.sort_by { _1[:score] }.reverse.map { _1[:position] })
  end
end
