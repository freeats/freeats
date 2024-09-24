# frozen_string_literal: true

require "test_helper"

class ScorecardTemplates::DestroyTest < ActiveSupport::TestCase
  test "should destroy scorecard_template, its associated events and questions" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    actor_account = accounts(:admin_account)
    scorecard_template = scorecard_templates(:ruby_position_contacted_scorecard_template)
    events = scorecard_template.events
    questions = scorecard_template.scorecard_template_questions
    position_stage = scorecard_template.position_stage

    assert_equal questions.count, 1
    assert_equal events.count, 1

    assert_difference ["ScorecardTemplateQuestion.count", "ScorecardTemplate.count"], -1 do
      assert_difference "Event.where(eventable: scorecard_template).count", -1 do
        assert_difference "Event.where(type: 'scorecard_template_removed').count" do
          ScorecardTemplates::Destroy.new(
            scorecard_template:,
            actor_account:
          ).call.value!
        end
      end
    end

    assert_empty questions

    scorecard_template_removed_event = Event.last

    assert_equal scorecard_template_removed_event.type, "scorecard_template_removed"
    assert_equal scorecard_template_removed_event.eventable, position_stage
    assert_equal scorecard_template_removed_event.actor_account, actor_account
  end

  test "should return Failure if scorecard template wasn't destroyed" do
    scorecard_template = scorecard_templates(:ruby_position_contacted_scorecard_template)
    actor_account = accounts(:admin_account)

    scorecard_template.stub(
      :destroy!,
      -> { raise ActiveRecord::RecordNotDestroyed.new("error message", scorecard_template) }
    ) do
      assert_no_difference [
        "Event.where(eventable: scorecard_template).count",
        "Event.where(type: 'scorecard_template_removed').count",
        "ScorecardTemplate.count"
      ] do
        result = ScorecardTemplates::Destroy.new(
          scorecard_template:,
          actor_account:
        ).call

        assert_equal result.failure.first, :scorecard_template_not_destroyed
      end
    end
  end
end
