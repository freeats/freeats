# frozen_string_literal: true

require "test_helper"

class Placement::ChangeStatusTest < ActiveSupport::TestCase
  setup do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
  end

  test "should change status and create event and disqualify_reason" do
    placement = placements(:sam_golang_replied)
    actor_account = accounts(:admin_account)
    old_status = placement.status
    new_status = "team_fit"

    assert_not DisqualifyReason.find_by(title: new_status.humanize)
    assert_equal placement.status, "qualified"
    assert_not placement.disqualify_reason
    assert_not_equal old_status, new_status

    assert_difference ["Event.count", "DisqualifyReason.count"] do
      placement = Placements::ChangeStatus.new(
        new_status:,
        placement:,
        actor_account:
      ).call.value!

      assert_equal placement.status, "disqualified"

      reason = placement.disqualify_reason

      assert reason
      assert_equal reason.title, new_status.humanize
      assert_equal reason.description,
                   I18n.t("candidates.disqualification.disqualify_statuses.#{new_status}")

      event = Event.last

      assert_equal event.actor_account_id, actor_account.id
      assert_equal event.type, "placement_changed"
      assert_equal event.eventable_id, placement.id
      assert_equal event.eventable_type, "Placement"
      assert_equal event.changed_field, "status"
      assert_equal event.changed_from, old_status
      assert_equal event.changed_to, new_status
    end
  end

  test "should change status, create event and not create disqualify_reason if it's already exists" do
    placement = placements(:sam_golang_replied)
    actor_account = accounts(:admin_account)
    old_status = placement.status
    new_status = "no_reply"

    assert DisqualifyReason.find_by(title: new_status.humanize)
    assert_equal placement.status, "qualified"
    assert_not placement.disqualify_reason
    assert_not_equal old_status, new_status

    assert_difference "Event.count" do
      assert_no_difference "DisqualifyReason.count" do
        placement = Placements::ChangeStatus.new(
          new_status:,
          placement:,
          actor_account:
        ).call.value!

        assert_equal placement.status, "disqualified"

        reason = placement.disqualify_reason

        assert reason
        assert_equal reason.title, new_status.humanize
        assert_equal reason.description,
                     I18n.t("candidates.disqualification.disqualify_statuses.#{new_status}")

        event = Event.last

        assert_equal event.actor_account_id, actor_account.id
        assert_equal event.type, "placement_changed"
        assert_equal event.eventable_id, placement.id
        assert_equal event.eventable_type, "Placement"
        assert_equal event.changed_field, "status"
        assert_equal event.changed_from, old_status
        assert_equal event.changed_to, new_status
      end
    end
  end

  test "should change status, create event and not create disqualify_reason " \
       "if status changed to reserved or qualified" do
    placement = placements(:sam_golang_replied)
    actor_account = accounts(:admin_account)
    old_status = placement.status
    new_status = "reserved"

    assert_equal placement.status, "qualified"
    assert_not placement.disqualify_reason
    assert_not_equal old_status, new_status

    assert_difference "Event.count" do
      assert_no_difference "DisqualifyReason.count" do
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
      end
    end
  end
end
