# frozen_string_literal: true

require "test_helper"

class Candidates::Interviews::ScheduleTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  test "should create schedule event" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    candidate = candidates(:jane)
    selected_time = Time.zone.now.to_datetime
    actor_account = accounts(:admin_account)

    Candidates::Interviews::Schedule.new(
      candidate:,
      selected_time:,
      actor_account:
    ).call.value!

    Event.last.tap do |event|
      assert_equal event.type, "candidate_interview_scheduled"
      assert_equal event.eventable, candidate
      assert_equal event.actor_account, actor_account
      assert_equal event.properties["scheduled_for"], selected_time.rfc3339
    end
  end
end
