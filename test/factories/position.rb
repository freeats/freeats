# frozen_string_literal: true

FactoryBot.define do
  factory :position do
    status { :draft }
    name { Faker::Job.title }
    location { Location.where(type: "city").sample }
    tenant { Tenant.find_by(name: "Toughbyte") }
  end
end
