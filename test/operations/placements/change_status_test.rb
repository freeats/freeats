# frozen_string_literal: true

require "test_helper"

class Placement::ChangeStatusTest < ActiveSupport::TestCase
  setup do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
  end

  test "should change status, create event and assign disqualify_reason" do
    placement = placements(:sam_golang_replied)
    actor_account = accounts(:admin_account)
    old_status = placement.status
    new_status = "disqualified"
    reason = disqualify_reasons(:no_reply_toughbyte)
    disqualify_reason_id = reason.id

    assert_equal placement.status, "qualified"
    assert_not placement.disqualify_reason

    assert_difference "Event.count" do
      placement = Placements::ChangeStatus.new(
        new_status:,
        disqualify_reason_id:,
        placement:,
        actor_account:
      ).call.value!
    end

    assert_equal placement.status, "disqualified"
    assert_equal placement.disqualify_reason, reason

    event = Event.last

    assert_equal event.actor_account_id, actor_account.id
    assert_equal event.type, "placement_changed"
    assert_equal event.eventable_id, placement.id
    assert_equal event.eventable_type, "Placement"
    assert_equal event.changed_field, "status"
    assert_equal event.changed_from, old_status
    assert_equal event.changed_to, new_status
    assert_equal event.properties["reason"], reason.title
  end

  test "should change status, create event and not assign disqualify_reason " \
       "if status changed to reserved or qualified" do
    placement = placements(:sam_golang_replied)
    actor_account = accounts(:admin_account)
    old_status = placement.status
    new_status = "reserved"

    assert_equal placement.status, "qualified"
    assert_not placement.disqualify_reason

    assert_difference "Event.count" do
      placement = Placements::ChangeStatus.new(
        new_status:,
        placement:,
        actor_account:
      ).call.value!
    end

    assert_equal placement.status, "reserved"
    assert_not placement.disqualify_reason

    event = Event.last

    assert_equal event.actor_account_id, actor_account.id
    assert_equal event.type, "placement_changed"
    assert_equal event.eventable_id, placement.id
    assert_equal event.eventable_type, "Placement"
    assert_equal event.changed_field, "status"
    assert_equal event.changed_from, old_status
    assert_equal event.changed_to, new_status
    assert_empty event.properties
  end

  test "should change status, create event and unassign disqualify_reason " \
       "if status changed from disqualified to qualified" do
    placement = placements(:sam_golang_sourced)
    actor_account = accounts(:admin_account)
    old_status = placement.status
    new_status = "qualified"

    assert_equal placement.status, "disqualified"
    assert placement.disqualify_reason

    assert_difference "Event.count" do
      placement = Placements::ChangeStatus.new(
        new_status:,
        placement:,
        actor_account:
      ).call.value!
    end

    assert_equal placement.status, "qualified"
    assert_not placement.disqualify_reason

    event = Event.last

    assert_equal event.actor_account_id, actor_account.id
    assert_equal event.type, "placement_changed"
    assert_equal event.eventable_id, placement.id
    assert_equal event.eventable_type, "Placement"
    assert_equal event.changed_field, "status"
    assert_equal event.changed_from, old_status
    assert_equal event.changed_to, new_status
    assert_empty event.properties
  end
end
