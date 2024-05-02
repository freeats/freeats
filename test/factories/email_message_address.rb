# frozen_string_literal: true

FactoryBot.define do
  factory :email_message_address do
    field { :from }
    address { Faker::Internet.email }
    position { 1 }
  end
end
