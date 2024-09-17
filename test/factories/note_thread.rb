# frozen_string_literal: true

FactoryBot.define do
  factory :note_thread do
    notable { Candidate.first }
    hidden { false }
    tenant { Tenant.find_by(name: "Toughbyte") }
  end
end
