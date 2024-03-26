# frozen_string_literal: true

require "test_helper"

class PositionsControllerTest < ActionDispatch::IntegrationTest
  test "should show position info" do
    get tab_ats_position_url(positions(:ruby_position), :info)

    assert_response :success
  end

  test "should reassign recruiter" do
    recruiter = members(:hiring_manager_member)
    position = positions(:ruby_position)

    patch reassign_recruiter_ats_position_path(position),
          params: { position: { recruiter_id: recruiter.id } }

    assert_response :success
    position.reload

    assert_equal position.recruiter, recruiter
  end

  test "shouldn't update a model without change_status_modal param" do
    position = positions(:ruby_position)
    patch change_status_ats_position_path(position, new_status: "passive")

    assert_not_equal position.reload.status, "passive"
    assert_response :success
  end

  test "should change status to closed, active and passive and create event" do
    comment = "Status change explanation"
    position = positions(:ruby_position)
    new_status_reason = "other"

    new_status = "closed"
    # TODO: uncomment event asserts when it will be added.
    # assert_difference "Event.count" => 9, "Task.count" => 3 do
    patch change_status_ats_position_path(position), params: {
      change_status_modal: "1",
      new_status:,
      new_change_status_reason: new_status_reason,
      comment:
    }
    # end
    assert_response :success
    position.reload

    assert_equal position.status, new_status
    assert_equal position.change_status_reason, new_status_reason

    # Event.where(type: :position_status_changed).last.tap do |event|
    #   assert_equal event.position_id, position.id
    #   assert_equal event.properties["to"], new_status
    #   assert_equal event.properties["comment"], comment
    #   assert_equal event.properties["change_status_reason"], new_status_reason
    # end

    new_status = "passive"
    # assert_difference "Event.count" do
    patch change_status_ats_position_path(position), params: {
      change_status_modal: "1",
      new_status:,
      new_change_status_reason: new_status_reason,
      comment:
    }
    # end
    assert_response :success
    position.reload

    assert_equal position.status, new_status
    assert_equal position.change_status_reason, new_status_reason

    # Event.where(type: :position_status_changed).last.tap do |event|
    #   assert_equal event.type, "position_status_changed"
    #   assert_equal event.position_id, position.id
    #   assert_equal event.properties["to"], new_status
    #   assert_equal event.properties["comment"], comment
    #   assert_equal event.properties["change_status_reason"], new_status_reason
    # end

    new_status = "active"
    # assert_difference "Event.count" => 4 do
    patch change_status_ats_position_path(position), params: {
      change_status_modal: "1",
      new_status:,
      new_change_status_reason: new_status_reason,
      comment:
    }
    # end

    assert_response :success
    position.reload

    assert_equal position.status, new_status
    assert_equal position.change_status_reason, "other"

    # Event.last(4).tap do |event|
    #   assert_equal(
    #     event.pluck(:type).sort,
    #     %w[position_status_changed task_added task_watcher_added task_watcher_added].sort
    #   )
    # end
  end

  test "should update description card and create event" do
    position = positions(:ruby_position)
    description = Faker::Lorem.paragraph_by_chars(number: 100)
    # assert_difference("Event.count") do
    patch update_card_ats_position_path(
      position,
      card_name: "description",
      params: {
        position: {
          description:
        }
      }
    )
    # end
    position.reload

    assert_equal position.description.body.to_plain_text, description
    # event = Event.where(type: :position_changed).last
    #
    # assert_equal event.actor_user_id, actor_user.id
    # assert_equal event.position_id, position.id
    # assert_equal event.properties["field"], "description"
  end

  test "should change status to close with reason and comment and create event" do
    position = positions(:ruby_position)
    close_reason = Position::CHANGE_STATUS_REASON_LABELS.keys.sample.to_s

    # assert_difference -> { Event.where(type: :position_status_changed).count } do
    patch change_status_ats_position_path(position), params: {
      change_status_modal: "1",
      new_status: "closed",
      new_change_status_reason: close_reason,
      comment: "explanation"
    }
    # end
    assert_response :success
    position.reload

    assert_equal position.status, "closed"
    assert_equal position.change_status_reason, close_reason

    # Event.where(type: :position_status_changed).last.tap do |event|
    #   assert_equal event.position_id, position.id
    #   assert_equal event.properties["to"], "closed"
    #   assert_equal event.properties["change_status_reason"], close_reason
    #   assert_equal event.properties["comment"], "explanation"
    # end
  end
end
