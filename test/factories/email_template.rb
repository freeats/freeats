# frozen_string_literal: true

FactoryBot.define do
  factory :email_template do
    name { Faker::Lorem.sentence }
    subject { Faker::Lorem.sentence }
    message { Faker::Lorem.paragraph }
    tenant { Tenant.find_by(name: "Toughbyte") }
  end
end
