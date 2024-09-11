# frozen_string_literal: true

require "test_helper"

class PlacementTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
  end

  test "should add placement and create event" do
    candidate = candidates(:jane)
    position = positions(:ruby_position)
    sourced_position_stage = position_stages(:ruby_position_sourced)
    actor_account = accounts(:admin_account)

    assert_difference "Placement.count" => 1, "Event.count" => 1 do
      placement = Placements::Add.new(
        params: {
          candidate_id: candidate.id,
          position_id: position.id
        },
        actor_account:
      ).call.value!

      assert_equal placement.position_stage_id, sourced_position_stage.id

      event = Event.last

      assert_equal event.actor_account_id, actor_account.id
      assert_equal event.type, "placement_added"
      assert_equal event.eventable_id, placement.id
      assert_equal event.eventable_type, "Placement"
    end
  end

  test "should not add placement if already exists and not allowed" do
    candidate = candidates(:john)
    position = positions(:ruby_position)

    placement = placements(:john_ruby_hired)

    result = Placements::Add.new(
      params: {
        candidate_id: candidate.id,
        position_id: position.id
      },
      actor_account: accounts(:admin_account)
    ).call

    assert_equal result, Failure[:placement_already_exists, placement]
  end

  test "should add placement if already exists and allowed" do
    candidate = candidates(:john)
    position = positions(:ruby_position)
    sourced_position_stage = position_stages(:ruby_position_sourced)

    result = Placements::Add.new(
      params: {
        candidate_id: candidate.id,
        position_id: position.id
      },
      create_duplicate_placement: true,
      actor_account: accounts(:admin_account)
    ).call.value!

    assert_equal result.position_stage_id, sourced_position_stage.id
  end

  test "should change stage and create event" do
    placement = placements(:sam_golang_sourced)
    actor_account = accounts(:admin_account)
    old_stage_id = placement.position_stage_id
    new_stage = placement.next_stage

    assert_difference "Event.count" => 1 do
      placement = Placements::ChangeStage.new(
        new_stage:,
        placement:,
        actor_account:
      ).call.value!

      assert_equal placement.position_stage.name, new_stage

      event = Event.last

      assert_equal event.actor_account_id, actor_account.id
      assert_equal event.type, "placement_changed"
      assert_equal event.eventable_id, placement.id
      assert_equal event.eventable_type, "Placement"
      assert_equal event.changed_field, "stage"
      assert_equal event.changed_from, old_stage_id
      assert_equal event.changed_to, placement.position_stage_id
    end
  end

  test "should change status and create event" do
    placement = placements(:sam_golang_sourced)
    actor_account = accounts(:admin_account)
    old_status = placement.status
    new_status = "overqualified"

    assert_not_equal old_status, new_status

    assert_difference "Event.count" => 1 do
      placement = Placements::ChangeStatus.new(
        new_status:,
        placement:,
        actor_account:
      ).call.value!

      assert_equal placement.status, new_status

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

  test "should destroy and create event" do
    placement = placements(:sam_golang_sourced)
    actor_account = accounts(:admin_account)

    # 'placement_added' event is destroyed with placement.
    assert_difference "Event.count" => 0, "Placement.count" => -1 do
      Placements::Destroy.new(
        placement:,
        actor_account:
      ).call.value!

      event = Event.last

      assert_equal event.actor_account_id, actor_account.id
      assert_equal event.type, "placement_removed"
      assert_equal event.eventable_id, placement.candidate.id
      assert_equal event.eventable_type, "Candidate"
      assert_equal event.properties["position_id"], placement.position_id
      assert_equal event.properties["placement_id"], placement.id
      assert_equal event.properties["placement_stage"], placement.stage
      assert_equal event.properties["placement_status"], placement.status
      assert_equal event.properties["added_actor_account_id"], placement.added_event.actor_account_id
      assert_in_delta Time.zone.parse(event.properties["added_at"]), placement.added_event.performed_at, 1
    end
  end
end
