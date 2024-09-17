# frozen_string_literal: true

require "test_helper"

class PositionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in accounts(:employee_account)
  end

  test "should show position info" do
    get tab_ats_position_url(positions(:ruby_position), :info)

    assert_response :success
  end

  test "should assign recruiter" do
    recruiter = members(:employee_member)
    position = positions(:golang_position)

    assert_nil position.recruiter_id

    assert_difference "Event.count", 1 do
      patch reassign_recruiter_ats_position_path(position),
            params: { position: { recruiter_id: recruiter.id } }
    end

    assert_response :success

    position.reload
    event = Event.last

    assert_equal position.recruiter_id, recruiter.id
    assert_equal event.type, "position_recruiter_assigned"
  end

  test "should reassign recruiter" do
    recruiter = members(:employee_member)
    position = positions(:ruby_position)

    assert position.recruiter_id
    assert_not_equal position.recruiter_id, recruiter.id

    assert_difference "Event.count", 2 do
      patch reassign_recruiter_ats_position_path(position),
            params: { position: { recruiter_id: recruiter.id } }
    end

    assert_response :success

    position.reload
    events = Event.last(2)

    assert_equal position.recruiter_id, recruiter.id
    assert_equal events.pluck(:type).sort,
                 %w[position_recruiter_assigned position_recruiter_unassigned].sort
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

    assert_difference "Event.count" do
      patch change_status_ats_position_path(position), params: {
        change_status_modal: "1",
        new_status:,
        new_change_status_reason: new_status_reason,
        comment:
      }
    end
    assert_response :success
    position.reload

    assert_equal position.status, new_status
    assert_equal position.change_status_reason, new_status_reason

    Event.where(type: :position_changed).last.tap do |event|
      assert_equal event.eventable_id, position.id
      assert_equal event.changed_to, new_status
      assert_equal event.properties["comment"], comment
      assert_equal event.properties["change_status_reason"], new_status_reason
    end

    new_status = "passive"
    assert_difference "Event.count" do
      patch change_status_ats_position_path(position), params: {
        change_status_modal: "1",
        new_status:,
        new_change_status_reason: new_status_reason,
        comment:
      }
    end
    assert_response :success
    position.reload

    assert_equal position.status, new_status
    assert_equal position.change_status_reason, new_status_reason

    Event.where(type: :position_changed).last.tap do |event|
      assert_equal event.type, "position_changed"
      assert_equal event.eventable_id, position.id
      assert_equal event.changed_to, new_status
      assert_equal event.properties["comment"], comment
      assert_equal event.properties["change_status_reason"], new_status_reason
    end

    new_status = "active"
    assert_difference "Event.count" do
      patch change_status_ats_position_path(position), params: {
        change_status_modal: "1",
        new_status:,
        new_change_status_reason: new_status_reason,
        comment:
      }
    end

    assert_response :success
    position.reload

    assert_equal position.status, new_status
    assert_equal position.change_status_reason, "other"

    assert_equal Event.last.type, "position_changed"
  end

  test "should change status to close with reason and comment and create event" do
    position = positions(:ruby_position)
    close_reason = Position::CHANGE_STATUS_REASON_LABELS.keys.sample.to_s

    assert_difference -> { Event.where(type: :position_changed).count } do
      patch change_status_ats_position_path(position), params: {
        change_status_modal: "1",
        new_status: "closed",
        new_change_status_reason: close_reason,
        comment: "explanation"
      }
    end
    assert_response :success
    position.reload

    assert_equal position.status, "closed"
    assert_equal position.change_status_reason, close_reason

    Event.where(type: :position_changed).last.tap do |event|
      assert_equal event.eventable_id, position.id
      assert_equal event.changed_to, "closed"
      assert_equal event.properties["change_status_reason"], close_reason
      assert_equal event.properties["comment"], "explanation"
    end
  end

  test "should update collaborators and create event" do
    position = positions(:ruby_position)
    params = {}
    params[:collaborator_ids] =
      Member
      .where(access_level: Position::COLLABORATORS_ACCESS_LEVEL)
      .where.not(id: position.recruiter_id)
      .where(tenant: tenants(:toughbyte_tenant))
      .order("random()")
      .first(3)
      .pluck(:id) -
      [position.recruiter_id, params[:recruiter_id]]

    assert_empty position.collaborators

    assert_difference "Event.count" do
      patch update_side_header_ats_position_path(position), params: { position: params }
    end

    assert_response :success
    position.reload
    event = Event.last

    assert_equal position.collaborator_ids.sort, params[:collaborator_ids].sort
    assert_equal event.type, "position_changed"
    assert_equal event.changed_field, "collaborators"
    assert_equal event.changed_to.sort, params[:collaborator_ids].sort
    assert_empty event.changed_from
  end

  test "should update hiring managers and create event" do
    position = positions(:ruby_position)
    params = {}
    params[:hiring_manager_ids] =
      Member
      .where(access_level: Position::HIRING_MANAGERS_ACCESS_LEVEL)
      .where.not(id: position.recruiter_id)
      .where(tenant: tenants(:toughbyte_tenant))
      .order("random()")
      .first(3)
      .pluck(:id) -
      [position.recruiter_id, params[:recruiter_id]]

    assert_empty position.hiring_managers

    assert_difference "Event.count" do
      patch update_side_header_ats_position_path(position), params: { position: params }
    end

    assert_response :success
    position.reload
    event = Event.last

    assert_equal position.hiring_manager_ids.sort, params[:hiring_manager_ids].sort
    assert_equal event.type, "position_changed"
    assert_equal event.changed_field, "hiring_managers"
    assert_equal event.changed_to.sort, params[:hiring_manager_ids].sort
    assert_empty event.changed_from
  end

  test "should update interviewers and create event" do
    position = positions(:ruby_position)
    params = {}
    params[:interviewer_ids] =
      Member
      .where(access_level: Position::INTERVIEWERS_ACCESS_LEVEL)
      .where.not(id: position.recruiter_id)
      .where(tenant: tenants(:toughbyte_tenant))
      .order("random()")
      .first(3)
      .pluck(:id) -
      [position.recruiter_id, params[:recruiter_id]]

    assert_empty position.hiring_managers

    assert_difference "Event.count" do
      patch update_side_header_ats_position_path(position), params: { position: params }
    end

    assert_response :success
    position.reload
    event = Event.last

    assert_equal position.interviewer_ids.sort, params[:interviewer_ids].sort
    assert_equal event.type, "position_changed"
    assert_equal event.changed_field, "interviewers"
    assert_equal event.changed_to.sort, params[:interviewer_ids].sort
    assert_empty event.changed_from
  end

  test "should add and then update position_stage with creating events" do
    position = positions(:ruby_position)

    assert_equal position.stages.pluck(:list_index), (1..4).to_a

    name = "New Stage"
    assert_difference "PositionStage.count" => 1, "Event.count" => 1 do
      patch update_card_ats_position_path(
        position,
        card_name: "pipeline",
        params: {
          position: {
            stages_attributes: { "0" => { name: } }
          }
        }
      )
    end

    assert_equal position.reload.stages.pluck(:list_index), (1..5).to_a

    added_stage = position.stages.find_by(name:)

    new_name = "New Stage Changed Name"
    assert_no_difference "PositionStage.count" do
      assert_difference "Event.count" do
        patch update_card_ats_position_path(
          position,
          card_name: "pipeline",
          params: {
            position: {
              stages_attributes: { "0" => { name: new_name, id: added_stage.id } }
            }
          }
        )
      end
    end

    assert_equal position.reload.stages.pluck(:list_index), (1..5).to_a
    assert_equal added_stage.reload.name, new_name
  end

  test "should not create event about changed position stage if nothing changed" do
    position = positions(:golang_position)
    position_stage = position_stages(:golang_position_verified)

    assert_no_difference "Event.count" do
      patch update_card_ats_position_path(
        position,
        card_name: "pipeline",
        params: {
          position: {
            stages_attributes: { "0" => { name: position_stage.name, id: position_stage.id } }
          }
        }
      )
    end
  end

  test "should show position activities" do
    sign_in accounts(:admin_account)
    get tab_ats_position_url(positions(:ruby_position), :activities)

    assert_response :success
  end

  test "should create the event about changed position name" do
    position = positions(:ruby_position)
    new_name = "Changed name"

    assert_not_equal position.name, new_name

    assert_difference "Event.count" do
      patch update_header_ats_position_path(position), params: { position: { name: new_name } }
    end

    position.reload
    event = Event.last

    assert_equal position.name, new_name
    assert_equal event.type, "position_changed"
    assert_equal event.changed_field, "name"
    assert_equal event.changed_to, new_name
  end

  test "should create the event about changed position description" do
    position = positions(:ruby_position)
    new_description = "Changed description"

    assert_not_includes position.description.to_s, new_description

    assert_difference "Event.count" do
      patch update_card_ats_position_path(position),
            params: { position: { description: new_description }, card_name: "description" }
    end

    position.reload
    event = Event.last
    html_description = "<div class=\"trix-content\">\n  #{new_description}\n</div>\n"

    assert_equal position.description.to_s, html_description
    assert_equal event.type, "position_changed"
    assert_equal event.changed_field, "description"
    assert_equal event.changed_to, html_description
  end

  test "should delete a position owned by the same tenant" do
    sign_out

    account = accounts(:admin_account)
    position = positions(:ruby_position)

    assert_equal position.tenant_id, account.tenant_id

    sign_in account
    assert_difference "Position.count", -1 do
      delete ats_position_path(position)
    end

    assert_redirected_to ats_positions_path
  end

  test "should return not_found when trying to delete a position belonging to another tenant" do
    sign_out

    account = accounts(:suroviy_grigoriy_account)
    position = positions(:ruby_position)

    assert_not_equal position.tenant_id, account.tenant_id

    sign_in account
    assert_no_difference "Position.count" do
      delete ats_position_path(position)
    end

    assert_response :not_found
  end
end
