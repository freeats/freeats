# frozen_string_literal: true

FactoryBot.define do
  factory :note do
    member { Member.first }
    association :note_thread, factory: :note_thread
    text { Faker::Lorem.sentences(number: 5, supplemental: true).join(" ") }
    tenant { Tenant.find_by(name: "Toughbyte") }

    after(:create) do |note, evaluator|
      note.events.create!(
        actor_account_id: evaluator.member.account.id,
        type: :note_added,
        tenant: note.tenant
      )
    end
  end
end
