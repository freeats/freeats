# frozen_string_literal: true

require "test_helper"

class PositionStageTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  test "should restrict to create position_stage with same name in same position" do
    position = positions(:ruby_position)
    sourced_position_stage = position_stages(:ruby_position_sourced)

    assert_equal position.id, sourced_position_stage.position_id

    assert_no_difference "PositionStage.count" do
      params = { position:, name: sourced_position_stage.name, list_index: 5 }
      case PositionStages::Add.new(params:).call
      in Failure[:position_stage_invalid, _errors]
        assert_equal _errors, ["Name has already been taken"]
      end
    end
  end

  test "should keep hired position_stage list_index at the end when we add a new position_stage, " \
       "and keep the correct values for position_stages list_index" do
    position = positions(:ruby_position)
    position_hired_stage = position_stages(:ruby_position_hired)

    assert_equal position_hired_stage.list_index, 4
    assert_equal position.stages.pluck(:list_index), (1..4).to_a

    assert_difference "PositionStage.count", 1 do
      params = { position:, name: "new Stage", list_index: 4 }
      new_stage = PositionStages::Add.new(params:).call.value!

      assert_equal new_stage.list_index, params[:list_index]
      assert_equal new_stage.name, params[:name]
    end

    assert_equal position_hired_stage.reload.list_index, 5
    assert_equal position.reload.stages.pluck(:list_index), (1..5).to_a
  end

  test "should keep hired position_stage list_index at the end when we edit existing position_stage" do
    position_replied_stage = position_stages(:ruby_position_replied)
    position_hired_stage = position_stages(:ruby_position_hired)

    assert_equal position_hired_stage.list_index, 4

    name = "New Stage name"
    changed_position_replied_stage =
      PositionStages::Change.new(params: { id: position_replied_stage.id, name: }).call.value!

    assert_equal position_hired_stage.reload.list_index, 4
    assert_equal changed_position_replied_stage.name, name
  end
end
