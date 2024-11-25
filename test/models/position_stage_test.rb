# frozen_string_literal: true

require "test_helper"

class PositionStageTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
  end

  test "should restrict to create position_stage with same name in same position" do
    position = positions(:ruby_position)
    sourced_position_stage = position_stages(:ruby_position_sourced)
    actor_account = accounts(:admin_account)

    assert_equal position.id, sourced_position_stage.position_id

    assert_no_difference "PositionStage.count" do
      params = { position:, name: sourced_position_stage.name, list_index: 5 }
      case PositionStages::Add.new(params:, actor_account:).call
      in Failure[:position_stage_invalid, errors]
        assert_equal errors, ["Stage name is not unique: Sourced"]
      end
    end
  end

  test "should keep hired position_stage list_index at the end when we add a new position_stage, " \
       "keep the correct values for position_stages list_index and create event" do
    position = positions(:ruby_position)
    position_hired_stage = position_stages(:ruby_position_hired)
    actor_account = accounts(:admin_account)

    assert_equal position_hired_stage.list_index, 4
    assert_equal position.stages.pluck(:list_index), (1..4).to_a

    params = { position:, name: "new Stage", list_index: 4 }
    assert_difference "PositionStage.count" => 1, "Event.count" => 1 do
      PositionStages::Add.new(params:, actor_account:).call.value!
    end

    new_stage = PositionStage.last
    new_event = Event.last

    assert_equal new_stage.list_index, params[:list_index]
    assert_equal new_stage.name, params[:name]

    assert_equal new_event.actor_account_id, actor_account.id
    assert_equal new_event.type, "position_stage_added"
    assert_equal new_event.eventable_id, new_stage.id
    assert_equal new_event.properties, { "name" => new_stage.name }

    assert_equal position_hired_stage.reload.list_index, 5
    assert_equal position.reload.stages.pluck(:list_index), (1..5).to_a
  end

  test "should keep hired position_stage list_index at the end when we edit existing position_stage" do
    position_replied_stage = position_stages(:ruby_position_replied)
    position_hired_stage = position_stages(:ruby_position_hired)
    actor_account = accounts(:admin_account)
    name = "New Stage name"

    assert_equal position_hired_stage.list_index, 4
    assert_not_equal position_replied_stage.name, name

    assert_no_difference "PositionStage.count" do
      assert_difference "Event.count" do
        PositionStages::Change.new(
          params: { id: position_replied_stage.id, name: },
          actor_account:
        ).call.value!
      end
    end

    assert_equal position_hired_stage.reload.list_index, 4
    assert_equal position_replied_stage.reload.name, name

    new_event = Event.last

    assert_equal new_event.actor_account_id, actor_account.id
    assert_equal new_event.type, "position_stage_changed"
    assert_equal new_event.changed_field, "name"
    assert_equal new_event.eventable_id, position_replied_stage.id
  end

  test "name should be unique across not deleted stages" do
    interviewed_stage = position_stages(:golang_position_interviewed)
    position = positions(:golang_position)
    actor_account = accounts(:admin_account)

    assert interviewed_stage.deleted

    assert_difference "PositionStage.count" do
      PositionStages::Add.new(
        params: {
          position:,
          name: interviewed_stage.name,
          list_index: position.stages.pluck(:list_index).max + 1
        },
        actor_account:
      ).call.value!
    end

    new_interviewed_stage = PositionStage.find_by(name: interviewed_stage.name, deleted: false)

    assert_predicate new_interviewed_stage, :valid?

    assert_no_difference "PositionStage.count" do
      result =
        PositionStages::Add.new(
          params: {
            position:,
            name: interviewed_stage.name,
            list_index: position.stages.pluck(:list_index).max + 1
          },
          actor_account:
        ).call

      assert_equal result.failure.first, :position_stage_invalid
      assert_equal result.failure.second, ["Stage name is not unique: #{interviewed_stage.name}"]
    end

    new_interviewed_stage.update!(deleted: true)

    assert_predicate new_interviewed_stage, :valid?
  end
end
