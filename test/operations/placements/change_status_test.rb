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
    new_status = "no_reply"

    assert DisqualifyReason.find_by(title: new_status.humanize)
    assert_equal placement.status, "qualified"
    assert_not placement.disqualify_reason
    assert_not_equal old_status, new_status

    assert_difference "Event.count" do
      placement = Placements::ChangeStatus.new(
        new_status:,
        placement:,
        actor_account:
      ).call.value!

      assert_equal placement.status, "disqualified"

      reason = placement.disqualify_reason

      assert reason
      assert_equal reason.title, new_status.humanize
      assert_equal reason.description, disqualify_reasons(:no_reply_toughbyte).description

      event = Event.last

      assert_equal event.actor_account_id, actor_account.id
      assert_equal event.type, "placement_changed"
      assert_equal event.eventable_id, placement.id
      assert_equal event.eventable_type, "Placement"
      assert_equal event.changed_field, "status"
      assert_equal event.changed_from, old_status
      assert_equal event.changed_to, new_status
      assert_equal event.properties["reason"], new_status.humanize
    end
  end

  test "should change status, create event and not assign disqualify_reason " \
       "if status changed to reserved or qualified" do
    placement = placements(:sam_golang_replied)
    actor_account = accounts(:admin_account)
    old_status = placement.status
    new_status = "reserved"

    assert_equal placement.status, "qualified"
    assert_not placement.disqualify_reason
    assert_not_equal old_status, new_status

    assert_difference "Event.count" do
      placement = Placements::ChangeStatus.new(
        new_status:,
        placement:,
        actor_account:
      ).call.value!

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
  end

  test "should change status, create event and unassign disqualify_reason " \
       "if status changed from disqualified to qualified" do
    placement = placements(:sam_golang_sourced)
    actor_account = accounts(:admin_account)
    old_status = placement.status
    new_status = "qualified"

    assert_equal placement.status, "disqualified"
    assert placement.disqualify_reason
    assert_not_equal old_status, new_status

    assert_difference "Event.count" do
      placement = Placements::ChangeStatus.new(
        new_status:,
        placement:,
        actor_account:
      ).call.value!

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
end