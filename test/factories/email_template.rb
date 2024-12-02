# frozen_string_literal: true

FactoryBot.define do
  factory :email_template do
    name { Faker::Lorem.sentence }
    subject { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph }
  end
end
