# frozen_string_literal: true

require "test_helper"

class Scorecards::DestroyTest < ActiveSupport::TestCase
  test "should destroy scorecard, its associated events and questions" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    actor_account = accounts(:admin_account)
    scorecard = scorecards(:ruby_position_contacted_scorecard)
    events = scorecard.events
    questions = scorecard.scorecard_questions
    placement = scorecard.placement

    assert_equal questions.count, 1
    assert_equal events.count, 1

    assert_difference ["ScorecardQuestion.count", "Scorecard.count"], -1 do
      assert_difference "Event.where(eventable: scorecard).count", -1 do
        assert_difference "Event.where(type: 'scorecard_removed').count" do
          Scorecards::Destroy.new(
            scorecard:,
            actor_account:
          ).call.value!
        end
      end
    end

    assert_empty questions

    scorecard_removed_event = Event.last

    assert_equal scorecard_removed_event.type, "scorecard_removed"
    assert_equal scorecard_removed_event.eventable, placement
    assert_equal scorecard_removed_event.actor_account, actor_account
  end

  test "should return Failure if scorecard wasn't destroyed" do
    scorecard = scorecards(:ruby_position_contacted_scorecard)
    actor_account = accounts(:admin_account)

    scorecard.stub(
      :destroy!,
      -> { raise ActiveRecord::RecordNotDestroyed.new("error message", scorecard) }
    ) do
      assert_no_difference [
        "Event.where(eventable: scorecard).count",
        "Event.where(type: 'scorecard_removed').count",
        "Scorecard.count"
      ] do
        result = Scorecards::Destroy.new(
          scorecard:,
          actor_account:
        ).call

        assert_equal result.failure.first, :scorecard_not_destroyed
      end
    end
  end
end
