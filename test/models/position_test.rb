# frozen_string_literal: true

require "test_helper"

class PositionTest < ActiveSupport::TestCase
  setup do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
  end

  test "should create position with events and default position_stages" do
    location = locations(:ta_xbiex_city)
    actor_account = accounts(:admin_account)
    params = {
      name: "Ruby    developer    ",
      status: :open,
      change_status_reason: :other,
      location_id: location.id
    }

    assert_difference "Position.count" => 1, "Event.count" => 8, "PositionStage.count" => 4 do
      position = Positions::Add.new(params:, actor_account:).call.value!

      assert_equal position.name, "Ruby developer"
      assert_equal position.location, location
      assert_equal position.stages.pluck(:name).sort, Position::DEFAULT_STAGES.sort
      assert_equal position.recruiter, actor_account.member

      position_added_event = Event.find_by(type: :position_added, eventable: position)
      position_recruiter_assigned_event = Event.find_by(type: :position_recruiter_assigned, eventable: position)
      name_position_changed_event = Event.find_by(type: :position_changed, changed_field: "name", eventable: position)
      location_position_changed_event = Event.find_by(type: :position_changed, changed_field: "location",
                                                      eventable: position)

      new_position_stages = PositionStage.where(position:)
      position_stage_added_events = Event.where(
        type: :position_stage_added, eventable: new_position_stages.ids
      ).to_a

      assert_equal position_added_event.actor_account_id, actor_account.id
      assert_equal position_added_event.type, "position_added"
      assert_equal position_added_event.eventable_id, position.id

      assert_equal position_recruiter_assigned_event.actor_account, actor_account
      assert_equal position_recruiter_assigned_event.type, "position_recruiter_assigned"
      assert_equal position_recruiter_assigned_event.changed_to, actor_account.member.id
      assert_equal position_recruiter_assigned_event.eventable_id, position.id

      assert_equal name_position_changed_event.actor_account_id, actor_account.id
      assert_equal name_position_changed_event.type, "position_changed"
      assert_equal name_position_changed_event.changed_to, "Ruby developer"
      assert_equal name_position_changed_event.eventable_id, position.id

      assert_equal location_position_changed_event.actor_account_id, actor_account.id
      assert_equal location_position_changed_event.type, "position_changed"
      assert_equal location_position_changed_event.changed_to, location.short_name
      assert_equal location_position_changed_event.eventable_id, position.id

      assert_equal position_stage_added_events.count, 4
      assert_equal position_stage_added_events.map(&:actor_account_id).uniq, [actor_account.id]
      assert_equal position_stage_added_events.map(&:type).uniq, ["position_stage_added"]
      assert_equal position_stage_added_events.map(&:eventable_id).sort,
                   new_position_stages.ids.sort
      assert_equal position_stage_added_events.map { _1.properties["name"] }.sort,
                   Position::DEFAULT_STAGES.sort
    end
  end

  test "should add new position_stage and keep the correct values for position_stages list_index" do
    position = positions(:ruby_position)
    actor_account = accounts(:admin_account)

    assert_equal position.stages.pluck(:list_index), (1..4).to_a

    stages_attributes = { "3" => { name: "New Stage" } }
    assert_difference "PositionStage.count" => 1, "Event.count" => 1 do
      Positions::ChangeStages.new(position:, stages_attributes:, actor_account:).call.value!
    end

    new_event = Event.last
    new_position_stage = PositionStage.last

    assert_equal new_event.actor_account_id, actor_account.id
    assert_equal new_event.type, "position_stage_added"
    assert_equal new_event.eventable_id, new_position_stage.id
    assert_equal new_event.properties, { "name" => new_position_stage.name }

    assert_equal position.reload.stages.pluck(:list_index), (1..5).to_a
  end

  test "position should be valid if recruiter, collaborator, hiring manager or interviewer is inactive" do
    inactive_member = members(:inactive_member)
    position = Position.new(name: "Name", recruiter: inactive_member)

    assert_predicate position, :valid?

    position.collaborators = [inactive_member]

    assert_predicate position, :valid?

    position.hiring_managers = [inactive_member]

    assert_predicate position, :valid?

    position.interviewers = [inactive_member]

    assert_predicate position, :valid?
  end

  test "location validation should only allow city or empty value" do
    position = positions(:ruby_position)

    position.location = nil

    assert_predicate position, :valid?

    position.location = locations(:ta_xbiex_city)

    assert_predicate position, :valid?

    position.location = locations(:armenia_country)

    assert_not position.valid?

    position.location = locations(:wien_admin_region1)

    assert_not position.valid?
  end

  test "active_recruiter_must_be_assigned_if_career_site_is_enabled should work" do
    position = positions(:closed_position)
    active_recruiter = members(:employee_member)
    inactive_recruiter = members(:inactive_member)

    position.tenant.career_site_enabled = true
    position.recruiter = nil

    assert_predicate position, :valid?

    position.status = "open"

    assert_not position.valid?
    assert_includes position.errors[:base], I18n.t("positions.recruiter_must_be_assigned_error")

    position.recruiter = inactive_recruiter

    assert_not position.valid?
    assert_includes position.errors[:base], I18n.t("positions.active_recruiter_must_be_assigned_error")

    position.recruiter = active_recruiter

    assert_predicate position, :valid?

    position.save!

    position.recruiter = nil

    assert_not position.valid?
    assert_includes position.errors[:base], I18n.t("positions.recruiter_must_be_assigned_error")

    position.recruiter = inactive_recruiter

    assert_not position.valid?
    assert_includes position.errors[:base], I18n.t("positions.active_recruiter_must_be_assigned_error")
  end
end
