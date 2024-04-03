# frozen_string_literal: true

require "test_helper"

class PositionStageTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  test "should restrict to create position_stage with same name in same position" do
    position = positions(:ruby_position)
    sourced_position_stage = position_stages(:ruby_position_sourced)

    assert_equal position.id, sourced_position_stage.position_id

    assert_no_difference "PositionStage.count" do
      case PositionStages::Add.new(params: { position:, name: sourced_position_stage.name }).call
      in Failure[:position_stage_invalid, _errors]
        assert_equal _errors, ["Name has already been taken"]
      end
    end
  end

  test "should keep hired position_stage list_index at the end when we add a new position_stage" do
    position = positions(:ruby_position)
    position_hired_stage = position_stages(:ruby_position_hired)

    assert_equal position_hired_stage.list_index, 4

    assert_difference "PositionStage.count", 1 do
      PositionStages::Add.new(params: { position:, name: "new_stage", list_index: 4 }).call
    end

    assert_equal position_hired_stage.reload.list_index, 5
  end

  test "should keep hired position_stage list_index at the end when we edit existing position_stage" do
    position_replied_stage = position_stages(:ruby_position_replied)
    position_hired_stage = position_stages(:ruby_position_hired)

    assert_equal position_hired_stage.list_index, 4

    new_list_index = 10
    PositionStages::Change.new(params: { list_index: new_list_index },
                               position_stage: position_replied_stage).call.value!

    assert_equal position_hired_stage.reload.list_index, new_list_index + 1
  end
end
