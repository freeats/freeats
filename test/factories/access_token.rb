# frozen_string_literal: true

FactoryBot.define do
  factory :access_token do
    context { :member_invitation }
    sent_to { Faker::Internet.email }
    sent_at { Time.zone.now }
    transient do
      token_value { "test" }
    end

    hashed_token { Digest::SHA256.digest(token_value) }
  end
end
