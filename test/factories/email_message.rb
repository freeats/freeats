# frozen_string_literal: true

FactoryBot.define do
  factory :email_message do
    message_id { "<#{Random.uuid}@testmail.com>" }
    in_reply_to { "" }
    timestamp { Time.now.to_i }
    subject { Faker::Dessert.flavor }
    plain_mime_type { "text/plain" }

    email_thread

    body_content = Faker::Lorem.sentences(number: 20, supplemental: true)
    plain_body { body_content.join("\n") }
    html_body { body_content.join("<br>") }

    transient do
      from { [Faker::Internet.email] }
      to { [Faker::Internet.email] }
    end

    trait :with_attachment do
      after(:create) do |email_message|
        remote_file = create(:remote_file)
        remote_file.update!(email_message_id: email_message.id)
      end
    end

    after(:create) do |email_message, evaluator|
      Array(evaluator.from).each_with_index do |from_email, index|
        create(:email_message_address,
               position: index + 1,
               address: from_email,
               field: :from,
               email_message:)
      end

      Array(evaluator.to).each_with_index do |to_email, index|
        create(:email_message_address,
               position: index + 1,
               address: to_email,
               field: :to,
               email_message:)
      end
    end
  end
end
