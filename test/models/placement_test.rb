# frozen_string_literal: true

require "test_helper"

class PlacementTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  test "should create placement" do
    candidate = candidates(:jane)
    position = positions(:ruby_position)
    sourced_position_stage = position_stages(:ruby_position_sourced)

    placement = Placements::Add.new(
      params: {
        candidate_id: candidate.id,
        position_id: position.id
      },
      actor_account: accounts(:admin_account)
    ).call.value!

    assert_equal placement.position_stage_id, sourced_position_stage.id
  end

  test "shouldn't create placement if already exists and not allowed" do
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

  test "should create placement if already exists and allowed" do
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
