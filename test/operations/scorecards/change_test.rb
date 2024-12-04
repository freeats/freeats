# frozen_string_literal: true

require "test_helper"

class Scorecards::ChangeTest < ActiveSupport::TestCase
  test "should update scorecard and create event" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    scorecard = scorecards(:ruby_position_replied_scorecard)
    actor_account = accounts(:admin_account)
    new_score = "relevant"
    new_interviewer = members(:employee_member)
    new_summary = "Test summary"
    questions_params = nil

    assert_equal scorecard.score, "good"
    assert_equal scorecard.interviewer_id, members(:helen_member).id
    assert_empty scorecard.summary.body.to_s

    params = {
      interviewer_id: new_interviewer.id,
      score: new_score,
      summary: new_summary
    }

    assert_difference "Event.where(type: 'scorecard_changed').count" do
      Scorecards::Change.new(
        scorecard:,
        params:,
        questions_params:,
        actor_account:
      ).call.value!
    end

    scorecard_changed_event = Event.where(type: :scorecard_changed).last

    assert_equal scorecard_changed_event.eventable, scorecard
    assert_equal scorecard_changed_event.actor_account, actor_account

    assert_equal scorecard.reload.score, new_score
    assert_equal scorecard.interviewer_id, new_interviewer.id
    # Summary is wrapped in trix tags.
    assert_equal scorecard.summary.body.to_s, "<div class=\"trix-content-custom\">\n  Test summary\n</div>\n"
    assert_equal scorecard.summary.body.to_plain_text, "Test summary"
  end

  test "should not create event if summary was not changed" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    scorecard = scorecards(:ruby_position_replied_scorecard)
    actor_account = accounts(:admin_account)
    interviewer = members(:helen_member)
    score = "good"
    questions_params = nil

    assert_equal scorecard.score, score
    assert_equal scorecard.interviewer_id, interviewer.id
    assert_empty scorecard.summary.body.to_s

    params = {
      interviewer_id: interviewer.id,
      score: "good",
      summary: ""
    }

    assert_no_difference "Event.count" do
      Scorecards::Change.new(
        scorecard:,
        params:,
        questions_params:,
        actor_account:
      ).call.value!
    end

    assert_equal scorecard.reload.score, score
    assert_equal scorecard.interviewer_id, interviewer.id
    # Summary is wrapped in trix tags.
    assert_equal scorecard.summary.body.to_s, "<div class=\"trix-content-custom\">\n  \n</div>\n"
    assert_equal scorecard.summary.body.to_plain_text, ""
  end
end
