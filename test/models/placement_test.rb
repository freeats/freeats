# frozen_string_literal: true

require "test_helper"

class PlacementTest < ActiveSupport::TestCase
  test "should create placement" do
    candidate = candidates(:john)
    position = positions(:ruby_position)
    sourced_position_stage = position_stages(:ruby_position_sourced)

    placement = Placements::Add.new(
      candidate_id: candidate.id,
      position_id: position.id,
      actor_account: accounts(:admin_account)
    ).call.value!

    assert_equal placement.position_stage_id, sourced_position_stage.id
  end

  test "should change stage" do
    placement = placements(:sam_golang_sourced)
    new_stage = placement.next_stage

    result = Placements::ChangeStage.new(
      new_stage:,
      placement:,
      actor_account: accounts(:admin_account)
    ).call.value!

    assert_equal result.position_stage.name, new_stage
  end

  test "should change status" do
    placement = placements(:sam_golang_sourced)
    new_status = "overqualified"

    assert_not_equal placement.status, new_status

    result = Placements::ChangeStatus.new(
      new_status:,
      placement:,
      actor_account: accounts(:admin_account)
    ).call.value!

    assert_equal result.status, new_status
  end
end
