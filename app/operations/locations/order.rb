# frozen_string_literal: true

class Locations::Order < ApplicationOperation
  include Dry::Monads[:result]

  option :locations, Types::Strict::Array.of(Types::Instance(Location))
  option :query, Types::Strict::String

  def call
    locations_with_score = locations.map do |location|
      location_score = SelectComponent::Score.new(text: location.name, query:).call.value!
      max_alias_score = location.aliases.map do |alias_name|
        SelectComponent::Score.new(text: alias_name, query:).call.value!
      end.max

      # All locations with population under `population_divider` are sorted by best-match.
      # All locations with population above `population_divider` are sorted by population.
      population_divider = 50_000.0
      score = [location_score, max_alias_score].max *
              [location.population / population_divider, 1].max

      { location:, score: }
    end

    Success(locations_with_score.sort_by { _1[:score] }.reverse.map { _1[:location] })
  end
end
