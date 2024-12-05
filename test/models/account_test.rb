# frozen_string_literal: true

require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "cascade_destroy should delete account and all related entities" do
    admin_account = accounts(:admin_account)
    admin_member = members(:admin_member)
    scorecard = scorecards(:ruby_position_contacted_scorecard)
    scorecard.update!(interviewer_id: admin_member.id)

    assert_not_empty admin_member.positions
    assert_not_empty admin_member.notes
    assert_not_empty admin_member.tasks
    assert_not_empty admin_member.scorecards
    assert_not_empty admin_member.assigned_events

    assert_no_difference "Account.count" do
      assert_raises ActiveRecord::DeleteRestrictionError do
        admin_account.destroy!
      end
    end

    assert_difference ["Account.count", "Member.count"], -1 do
      assert admin_account.cascade_destroy
    end
  end
end
