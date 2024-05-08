# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    name { Faker::Lorem.sentence }
    status { :open }
    assignee { Member.first }
    due_date { 1.day.from_now }
  end
end
