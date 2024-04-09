# frozen_string_literal: true

require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "should create position with events and default position_stages" do
    actor_account = accounts(:admin_account)
    params = {
      name: "Ruby    developer    ",
      status: :active,
      change_status_reason: :other
    }

    assert_difference "Position.count" => 1, "Event.count" => 3, "PositionStage.count" => 4 do
      position = Positions::Add.new(params:, actor_account:).call.value!

      assert_equal position.name, "Ruby developer"
      assert_equal position.stages.pluck(:name).sort, Position::DEFAULT_STAGES.sort
      assert_equal position.recruiter, actor_account.member

      position_added_event = Event.find_by(type: :position_added, eventable: position)
      position_recruiter_assigned_event = Event.find_by(type: :position_recruiter_assigned, eventable: position)
      position_changed_event = Event.find_by(type: :position_changed, eventable: position)

      assert_equal position_added_event.actor_account_id, actor_account.id
      assert_equal position_added_event.type, "position_added"
      assert_equal position_added_event.eventable_id, position.id

      assert_equal position_recruiter_assigned_event.actor_account, actor_account
      assert_equal position_recruiter_assigned_event.type, "position_recruiter_assigned"
      assert_equal position_recruiter_assigned_event.changed_to, actor_account.member.id
      assert_equal position_recruiter_assigned_event.eventable_id, position.id

      assert_equal position_changed_event.actor_account_id, actor_account.id
      assert_equal position_changed_event.type, "position_changed"
      assert_equal position_changed_event.changed_field, "name"
      assert_equal position_changed_event.changed_to, "Ruby developer"
      assert_equal position_changed_event.eventable_id, position.id
    end
  end

  test "should add new position_stage and keep the correct values for position_stages list_index" do
    position = positions(:ruby_position)

    assert_equal position.stages.pluck(:list_index), (1..4).to_a

    stages_attributes = { "3" => { name: "New Stage" } }
    Positions::ChangeStages.new(position:, stages_attributes:).call.value!

    assert_equal position.reload.stages.pluck(:list_index), (1..5).to_a
  end

  test "position should be valid if recruiter or collaborator are invalid" do
    inactive_member = members(:inactive_member)
    position = Position.new(name: "Name", recruiter: inactive_member)

    assert_predicate position, :valid?

    position.collaborators = [inactive_member]

    assert_predicate position, :valid?
  end
end
