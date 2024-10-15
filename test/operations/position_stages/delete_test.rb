# frozen_string_literal: true

require "test_helper"

class PositionStages::DeleteTest < ActiveSupport::TestCase
  test "should mark position_stage as deleted; update list_index for other position's stages; " \
       "create position_stage_removed event associated with position; " \
       "delete scorecard_template and its questions; " \
       "move all placements to specified neighbor stage" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)

    position = positions(:golang_position)
    sourced_position_stage = position_stages(:golang_position_sourced)
    contacted_position_stage = position_stages(:golang_position_contacted)
    replied_position_stage = position_stages(:golang_position_replied)
    position_stage_to_delete = position_stages(:golang_position_verified)
    interviewed_position_stage = position_stages(:golang_position_interviewed)
    hired_position_stage = position_stages(:golang_position_hired)
    placement = placements(:sam_golang_replied)
    placement.update!(position_stage: position_stage_to_delete)
    actor_account = accounts(:admin_account)
    stage_to_move_placements_to = "Replied"
    scorecard_template =
      ScorecardTemplate.create!(
        position_stage: position_stage_to_delete,
        title: "golang position verified scorecard template"
      )

    assert_not position_stage_to_delete.deleted
    assert interviewed_position_stage.deleted
    assert_equal sourced_position_stage.list_index, 1
    assert_equal contacted_position_stage.list_index, 2
    assert_equal replied_position_stage.list_index, 3
    assert_equal position_stage_to_delete.list_index, 4
    assert_equal interviewed_position_stage.list_index, 5
    assert_equal hired_position_stage.list_index, 5
    assert_equal position.stages.count, 5
    assert_equal position.stages_including_deleted.count, 6

    assert_difference "ScorecardTemplate.where(position_stage: position_stage_to_delete).count", -1 do
      assert_difference "Event.where(type: 'position_stage_removed').count" do
        PositionStages::Delete
          .new(
            position_stage: position_stage_to_delete,
            actor_account:,
            stage_to_move_placements_to:
          ).call.value!
      end
    end

    assert position_stage_to_delete.deleted
    assert_equal sourced_position_stage.reload.list_index, 1
    assert_equal contacted_position_stage.reload.list_index, 2
    assert_equal replied_position_stage.reload.list_index, 3
    assert_equal position_stage_to_delete.list_index, 4
    assert_equal hired_position_stage.reload.list_index, 4
    assert_equal position.stages.count, 4
    assert_equal position.stages_including_deleted.count, 6
    assert_equal placement.reload.position_stage, replied_position_stage
    assert_nil ScorecardTemplate.find_by(id: scorecard_template.id)

    position_stage_removed_event = Event.where(type: "position_stage_removed").last

    assert_equal position_stage_removed_event.eventable, position
  end

  test "should return failure on attempt to delete an already deleted stage" do
    position_stage = position_stages(:golang_position_interviewed)
    actor_account = accounts(:admin_account)

    assert position_stage.deleted

    result = PositionStages::Delete.new(position_stage:, actor_account:).call

    assert_equal result, Failure(:stage_already_deleted)
  end

  test "should return failure on attempt to move placements to an already deleted stage" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    actor_account = accounts(:admin_account)

    position_stage_to_delete = position_stages(:golang_position_verified)
    interviewed_stage = position_stages(:golang_position_interviewed)

    assert_not_empty position_stage_to_delete.placements
    assert interviewed_stage.deleted

    result = PositionStages::Delete.new(
      position_stage: position_stage_to_delete,
      actor_account:,
      stage_to_move_placements_to: interviewed_stage.name
    ).call

    assert_equal result, Failure(:new_stage_invalid)
  end

  test "should return failure on attempt to delete one of default stages" do
    position_stage = position_stages(:golang_position_sourced)
    actor_account = accounts(:admin_account)

    result = PositionStages::Delete.new(position_stage:, actor_account:).call

    assert_equal result, Failure(:default_stage_cannot_be_deleted)
  end
end
