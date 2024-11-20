# frozen_string_literal: true

require "test_helper"

class CandidatesHelperTest < ActionView::TestCase
  include ApplicationHelper
  include CandidatesHelper
  include ATS::TasksHelper
  include Rails.application.routes.url_helpers

  setup do
    @event = Event.new(performed_at: Time.current)
  end

  test "candidate_display_activity with candidate_added, method manual and actor_account_id present" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "candidate_added"
    @event.properties = { "method" => "manual" }
    @event.actor_account = accounts(:admin_account)

    result = candidate_display_activity(@event)

    assert_match("<span><b>#{@event.actor_account.name}</b> added the candidate manually</span>", result)
  end

  test "candidate_display_activity with candidate_added and method applied" do
    @event.actor_account_id = nil
    @event.type = "candidate_added"
    @event.properties = { "method" => "applied" }

    result = candidate_display_activity(@event)

    assert_match("<span>FreeATS added the candidate</span>", result)
  end

  test "candidate_display_activity with candidate_added, method api and actor_account_id blank" do
    @event.actor_account_id = nil
    @event.type = "candidate_added"
    @event.properties = { "method" => "api" }

    result = candidate_display_activity(@event)

    assert_match(/FreeATS added the candidate using extension/, result)
  end

  test "candidate_display_activity with placement_added and applied true" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "placement_added"
    @event.properties = { "applied" => true }
    @event.actor_account = accounts(:admin_account)
    @event.eventable = placements(:sam_ruby_replied)

    result = candidate_display_activity(@event)

    assert_match "<span>Candidate applied to <a href=\"/ats/positions/#{@event.eventable.position.id
                                                                      }\">Ruby developer</a></span>", result
  end

  test "candidate_display_activity with placement_added and applied false" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "placement_added"
    @event.properties = { "applied" => false }
    @event.actor_account = accounts(:admin_account)
    @event.eventable = placements(:sam_ruby_replied)

    result = candidate_display_activity(@event)

    assert_match "<b>Admin Admin</b> assigned the candidate to <a href=\"/ats/positions/#{
                 @event.eventable.position.id }\">Ruby developer</a></span>", result
  end

  test "candidate_display_activity with email_received" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "email_received"
    @event.actor_account = accounts(:admin_account)
    @event.eventable = email_messages(:john_msg1)

    result = candidate_display_activity(@event)

    assert_match "<span>The candidate sent the email <b>", result
    assert_match @event.eventable.subject, result
    assert_match @event.eventable.plain_body.truncate(180), result
  end

  test "candidate_display_activity with email_sent" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "email_sent"
    @event.actor_account = accounts(:admin_account)
    @event.eventable = email_messages(:john_msg1)

    result = candidate_display_activity(@event)

    assert_match "span><b>#{@event.actor_account.name}</b> sent\nthe email <b>#{@event.eventable.subject}</b>", result
    assert_match @event.eventable.plain_body.truncate(180), result
  end

  test "candidate_display_activity with active_storage_attachment_added" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "active_storage_attachment_added"
    @event.properties = { "name" => "Resume.pdf" }
    @event.actor_account = accounts(:admin_account)

    result = candidate_display_activity(@event)

    assert_match "<span><b>#{@event.actor_account.name}</b> added file <b>Resume.pdf</b></span", result
  end

  test "candidate_display_activity with active_storage_attachment_removed" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "active_storage_attachment_removed"
    @event.properties = { "name" => "Resume.pdf" }
    @event.actor_account = accounts(:admin_account)

    result = candidate_display_activity(@event)

    assert_match "<span><b>#{@event.actor_account.name}</b> removed file <b>Resume.pdf</b></span>", result
  end

  test "candidate_display_activity with note_added" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "note_added"
    @event.actor_account = accounts(:admin_account)
    @event.eventable = notes(:admin_member_short_note)

    result = candidate_display_activity(@event)

    assert_match "<span><b>Admin Admin</b> added a note <blockquote", result
    assert_match @event.eventable.text, result
  end

  test "candidate_display_activity with note_removed" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "note_removed"
    @event.actor_account = accounts(:admin_account)

    result = candidate_display_activity(@event)

    assert_match "<span><b>#{@event.actor_account.name}</b> removed a note</span", result
  end

  test "candidate_display_activity with placement_removed" do
    position = positions(:ruby_position)
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "placement_removed"
    @event.properties = { "position_id" => position.id }
    @event.actor_account = accounts(:admin_account)

    result = candidate_display_activity(@event)

    assert_match "<span><b>#{@event.actor_account.name}</b> unassigned the candidate from " \
                 "<a href=\"/ats/positions/#{position.id}\">#{position.name}</a></span>", result
  end

  test "candidate_display_activity with scorecard_added" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "scorecard_added"
    @event.actor_account = accounts(:admin_account)

    @event.eventable = scorecards(:ruby_position_contacted_scorecard)

    result = candidate_display_activity(@event)

    assert_match "<span><b>#{@event.actor_account.name
                           }</b> added scorecard <a href=\"/ats/scorecards/#{
                            @event.eventable.id}\">Contacted stage scorecard template scorecard</a> for " \
                            "<a href=\"/ats/positions/#{@event.eventable.placement.position.id}\">#{
                 @event.eventable.placement.position.name}</a></span>", result
  end

  test "candidate_display_activity with scorecard_removed" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "scorecard_removed"
    @event.changed_from = "Technical Interview"
    @event.actor_account = accounts(:admin_account)
    @event.eventable = placements(:sam_ruby_replied)

    result = candidate_display_activity(@event)

    assert_match "<span><b>#{@event.actor_account.name
                           }</b> removed scorecard <b>Technical Interview</b> for <a href=\"/ats/positions/#{
                 @event.eventable.position.id}\">#{
                 @event.eventable.position.name}</a></span>", result
  end

  test "candidate_display_activity with scorecard_changed" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "scorecard_changed"
    @event.actor_account = accounts(:admin_account)

    @event.eventable = scorecards(:ruby_position_contacted_scorecard)

    result = candidate_display_activity(@event)

    assert_match "<span><b>#{@event.actor_account.name
                           }</b> updated scorecard <a href=\"/ats/scorecards/#{
                            @event.eventable.id}\">Contacted stage scorecard template scorecard</a> " \
                            "for <a href=\"/ats/positions/#{@event.eventable.placement.position.id}\">#{
                 @event.eventable.placement.position.name}</a></span>", result
  end

  test "candidate_display_activity with task_added" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "task_added"
    @event.actor_account = accounts(:admin_account)
    @event.eventable = tasks(:position)

    result = candidate_display_activity(@event)

    assert_match "<span><b>#{@event.actor_account.name
                           }</b> created <b>#{@event.eventable.name}</b> task</span>", result
  end

  test "candidate_display_activity with task_status_changed to open" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "task_status_changed"
    @event.changed_to = "open"
    @event.actor_account = accounts(:admin_account)
    @event.eventable = tasks(:candidate3)

    result = candidate_display_activity(@event)

    assert_match "<span><b>#{@event.actor_account.name}</b> reopened <b>#{@event.eventable.name}</b> task</span>",
                 result
  end

  test "candidate_display_activity with task_status_changed to closed" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "task_status_changed"
    @event.changed_to = "closed"
    @event.actor_account = accounts(:admin_account)
    @event.eventable = tasks(:candidate4)

    result = candidate_display_activity(@event)

    assert_match "<span><b>#{@event.actor_account.name}</b> closed <b>#{@event.eventable.name}</b> task</span>", result
  end

  test "candidate_display_activity with task_changed" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.type = "task_changed"
    @event.actor_account = accounts(:admin_account)
    @event.eventable = tasks(:candidate5)
    @event.changed_field = "name"
    @event.changed_from = "test old"
    @event.changed_to = "test new"

    result = candidate_display_activity(@event)

    assert_match "<span><b>#{
                 @event.actor_account.name}</b> changed <b>#{
                 @event.eventable.name}</b> task's Name from <b>test old</b> to <b>test new</b></span>", result
  end

  test "candidate_display_activity with nil event type" do
    @event.actor_account_id = accounts(:admin_account).id
    @event.actor_account = accounts(:admin_account)

    result = candidate_display_activity(@event)

    assert_nil(result)
  end
end
