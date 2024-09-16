# frozen_string_literal: true

require "test_helper"

class Candidates::Interviews::ResolveTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
  end

  test "should create resolved event only if resolved event isn't exists" do
    status = "passed"
    scheduled_event = events(:jake_candidate_interview_scheduled).becomes(Candidate::Interview)
    actor_account = accounts(:admin_account)

    Candidates::Interviews::Resolve.new(
      status:,
      scheduled_event:,
      actor_account:
    ).call.value!

    Candidate::Interview.last.tap do |event|
      assert_equal event.type, "candidate_interview_resolved"
      assert_equal event.eventable, scheduled_event.eventable
      assert_equal event.actor_account, actor_account
      assert_equal event.properties["status"], status
      assert_equal event.properties["pair_event_id"], scheduled_event.id
    end

    result = Candidates::Interviews::Resolve.new(
      status:,
      scheduled_event:,
      actor_account:
    ).call

    assert_equal result, Failure(:already_resolved)
  end

  test "shouldn't create event if have been passed not scheduled event" do
    actor_account = accounts(:admin_account)

    result = Candidates::Interviews::Resolve.new(
      status: "failed",
      scheduled_event:
        Event.where.not(type: :candidate_interview_scheduled).first.becomes(Candidate::Interview),
      actor_account:
    ).call

    assert_equal result, Failure(:not_scheduled_event_type)
  end
end
