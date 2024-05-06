# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    performed_at { Time.zone.now }
  end
end
