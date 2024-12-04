# frozen_string_literal: true

require "test_helper"

class PositionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in accounts(:employee_account)
  end

  test "should show position tabs" do
    position = positions(:ruby_position)

    get tab_ats_position_path(position, :info)

    assert_response :success

    get tab_ats_position_path(position, :pipeline)

    assert_response :success

    get tab_ats_position_path(position, :tasks)

    assert_response :success

    get tab_ats_position_path(position, :activities)

    assert_response :success
  end

  test "should assign recruiter" do
    recruiter = members(:employee_member)
    position = positions(:golang_position)

    assert_nil position.recruiter_id

    assert_difference "Event.count", 1 do
      patch update_side_header_ats_position_path(position),
            params: { position: { recruiter_id: recruiter.id } }
    end

    assert_response :success

    position.reload
    event = Event.last

    assert_equal position.recruiter_id, recruiter.id
    assert_equal event.type, "position_recruiter_assigned"
    assert_equal event.changed_to, recruiter.id
  end

  test "should reassign recruiter" do
    recruiter = members(:employee_member)
    position = positions(:ruby_position)

    assert position.recruiter_id
    assert_not_equal position.recruiter_id, recruiter.id

    assert_difference "Event.count", 2 do
      patch update_side_header_ats_position_path(position),
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
    patch change_status_ats_position_path(position, new_status: "on_hold")

    assert_not_equal position.reload.status, "on_hold"
    assert_response :success
  end

  test "should change status to closed, open and on_hold and create event" do
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

    new_status = "on_hold"
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

    new_status = "open"
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
    params[:collaborator_ids] = [members(:employee_member).id, members(:admin_member).id]

    assert_empty position.collaborators

    assert_difference "Event.where(type: :position_collaborator_assigned).count" => params[:collaborator_ids].size do
      patch update_side_header_ats_position_path(position), params: { position: params }
    end

    assert_response :success
    position.reload
    events = Event.last(params[:collaborator_ids].size)

    assert_equal position.collaborator_ids.sort, params[:collaborator_ids].sort
    assert_equal events.pluck(:type).uniq, ["position_collaborator_assigned"]
    assert_equal events.pluck(:changed_to).sort, params[:collaborator_ids].sort
    assert_empty events.pluck(:changed_from).compact
  end

  test "should update hiring managers and create event" do
    position = positions(:ruby_position)
    params = {}
    params[:hiring_manager_ids] = [members(:employee_member).id, members(:admin_member).id]

    assert_empty position.hiring_managers

    assert_difference(
      "Event.where(type: :position_hiring_manager_assigned).count" => params[:hiring_manager_ids].size
    ) do
      patch update_side_header_ats_position_path(position), params: { position: params }
    end

    assert_response :success
    position.reload
    events = Event.last(params[:hiring_manager_ids].size)

    assert_equal position.hiring_manager_ids.sort, params[:hiring_manager_ids].sort
    assert_equal events.pluck(:type).uniq, ["position_hiring_manager_assigned"]
    assert_equal events.pluck(:changed_to).sort, params[:hiring_manager_ids].sort
    assert_empty events.pluck(:changed_from).compact
  end

  test "should update interviewers and create event" do
    position = positions(:ruby_position)
    params = {}
    params[:interviewer_ids] = [members(:employee_member).id, members(:admin_member).id]

    assert_empty position.interviewers

    assert_difference(
      "Event.where(type: :position_interviewer_assigned).count" => params[:interviewer_ids].size
    ) do
      patch update_side_header_ats_position_path(position), params: { position: params }
    end

    assert_response :success
    position.reload
    events = Event.last(params[:interviewer_ids].size)

    assert_equal position.interviewer_ids.sort, params[:interviewer_ids].sort
    assert_equal events.pluck(:type).uniq, ["position_interviewer_assigned"]
    assert_equal events.pluck(:changed_to).sort, params[:interviewer_ids].sort
    assert_empty events.pluck(:changed_from).compact
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
    get tab_ats_position_path(positions(:ruby_position), :activities)

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
    html_description = "<div class=\"trix-content-custom\">\n  #{new_description}\n</div>\n"

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

    account = accounts(:acme_grigoriy_account)
    position = positions(:ruby_position)

    assert_not_equal position.tenant_id, account.tenant_id

    sign_in account
    assert_no_difference "Position.count" do
      delete ats_position_path(position)
    end

    assert_response :not_found
  end

  test "should update position location" do
    position = positions(:ruby_position)
    new_location = locations(:valencia_city)
    old_location = position.location

    assert_not_equal position.location_id, new_location.id

    assert_difference "Event.count" do
      patch update_header_ats_position_path(position), params: { position: { location_id: new_location.id } }
    end

    assert_equal position.reload.location_id, new_location.id

    event = Event.last

    assert_equal event.type, "position_changed"
    assert_equal event.changed_field, "location"
    assert_equal event.changed_to, new_location.short_name
    assert_equal event.changed_from, old_location.short_name
  end

  test "should display assigned and unassigned activities" do
    location = locations(:helsinki_city)
    position_name = "New position"
    # create recruiter assign and unassign events
    assert_difference ["Position.count", "Event.where(type: :position_recruiter_assigned).count"] do
      post ats_positions_path(position: { name: position_name, location_id: locations(:helsinki_city).id })
    end

    assert_response :redirect

    position = Position.last

    assert_equal position.location_id, location.id
    assert_equal position.name, position_name

    assert_difference(
      "Event.where(type: %i[position_recruiter_assigned position_recruiter_unassigned]).count", 2
    ) do
      patch update_side_header_ats_position_path(position),
            params: { position: { recruiter_id: members(:admin_member).id } }
    end

    assign_members1 = [members(:employee_member).id, members(:admin_member).id]
    assign_members2 = [members(:helen_member).id]

    # create collaborator assign and unassign events
    params = { collaborator_ids: assign_members1 }
    assert_difference(
      "Event.where(type: :position_collaborator_assigned).count" => params[:collaborator_ids].size
    ) do
      patch update_side_header_ats_position_path(position), params: { position: params }
    end

    removed_collaborators_size = params[:collaborator_ids].size
    params = { collaborator_ids: assign_members2 }
    assert_difference(
      "Event.where(type: :position_collaborator_assigned).count" => params[:collaborator_ids].size,
      "Event.where(type: :position_collaborator_unassigned).count" => removed_collaborators_size
    ) do
      patch update_side_header_ats_position_path(position), params: { position: params }
    end

    # create hiring manager assign and unassign events
    params = { hiring_manager_ids: assign_members1 }
    assert_difference(
      "Event.where(type: :position_hiring_manager_assigned).count" => params[:hiring_manager_ids].size
    ) do
      patch update_side_header_ats_position_path(position), params: { position: params }
    end

    removed_hiring_managers_size = params[:hiring_manager_ids].size
    params = { hiring_manager_ids: assign_members2 }
    assert_difference(
      "Event.where(type: :position_hiring_manager_assigned).count" => params[:hiring_manager_ids].size,
      "Event.where(type: :position_hiring_manager_unassigned).count" => removed_hiring_managers_size
    ) do
      patch update_side_header_ats_position_path(position), params: { position: params }
    end

    # create interviewer assign and unassign events
    params = { interviewer_ids: assign_members1 }
    assert_difference(
      "Event.where(type: :position_interviewer_assigned).count" => params[:interviewer_ids].size
    ) do
      patch update_side_header_ats_position_path(position), params: { position: params }
    end

    removed_interviewers_size = params[:interviewer_ids].size
    params = { interviewer_ids: assign_members2 }
    assert_difference(
      "Event.where(type: :position_interviewer_assigned).count" => params[:interviewer_ids].size,
      "Event.where(type: :position_interviewer_unassigned).count" => removed_interviewers_size
    ) do
      patch update_side_header_ats_position_path(position), params: { position: params }
    end

    get tab_ats_position_path(position, :activities)

    activities =
      Nokogiri::HTML(response.body)
              .css("#ats-positions-show-activities #activities div")
              .map { _1.at_css(":nth-child(2)").text.strip }

    reference_activities = [
      # recruiter
      "Adrian Barton assigned themselves as recruiter to the position",
      "Adrian Barton unassigned themselves as recruiter from the position",
      "Adrian Barton assigned Admin Admin as recruiter to the position",
      # collaborator
      "Adrian Barton assigned Admin Admin as collaborator to the position",
      "Adrian Barton assigned themselves as collaborator to the position",
      "Adrian Barton unassigned Admin Admin as collaborator from the position",
      "Adrian Barton unassigned themselves as collaborator from the position",
      "Adrian Barton assigned Helen Booker as collaborator to the position",
      # hiring manager
      "Adrian Barton assigned Admin Admin as hiring manager to the position",
      "Adrian Barton assigned themselves as hiring manager to the position",
      "Adrian Barton unassigned Admin Admin as hiring manager from the position",
      "Adrian Barton unassigned themselves as hiring manager from the position",
      "Adrian Barton assigned Helen Booker as hiring manager to the position",
      # interviewer
      "Adrian Barton assigned Admin Admin as interviewer to the position",
      "Adrian Barton assigned themselves as interviewer to the position",
      "Adrian Barton unassigned Admin Admin as interviewer from the position",
      "Adrian Barton unassigned themselves as interviewer from the position",
      "Adrian Barton assigned Helen Booker as interviewer to the position",
      # position location
      "Adrian Barton added location Helsinki, Finland",
      # position name
      "Adrian Barton added name New position"
    ]

    assert_empty(reference_activities - activities)
  end
end
