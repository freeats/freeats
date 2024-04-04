# frozen_string_literal: true

require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "should create position with default position_stages" do
    actor_account = accounts(:admin_account)
    params = {
      name: "Ruby    developer    ",
      status: :active,
      change_status_reason: :other
    }
    position = Positions::Add.new(params:, actor_account:).call.value!

    assert_equal position.name, "Ruby developer"
    assert_equal position.stages.pluck(:name).sort, Position::DEFAULT_STAGES.sort
    assert_equal position.recruiter, actor_account.member
  end

  test "should add new position_stage and keep the correct values for position_stages list_index" do
    position = positions(:ruby_position)

    assert_equal position.stages.pluck(:list_index), (1..4).to_a

    stages_attributes = { "3" => { name: "New Stage" } }
    Positions::ChangeStages.new(position:, stages_attributes:).call.value!

    assert_equal position.reload.stages.pluck(:list_index), (1..5).to_a
  end
end
