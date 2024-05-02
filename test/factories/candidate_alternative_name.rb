# frozen_string_literal: true

FactoryBot.define do
  factory :candidate_alternative_name do
    name { Faker::Name.unique.name }
  end
end
