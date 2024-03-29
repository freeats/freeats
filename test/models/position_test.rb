# frozen_string_literal: true

require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "should create position with default position_stages" do
    actor_account = accounts(:admin_account)
    params = {
      name: "Ruby    developer    ",
      status: :active,
      change_status_reason: :other
    }
    position = Positions::Add.new(params:, actor_account:).call.value!

    assert_equal position.name, "Ruby developer"
    assert_equal position.stages.pluck(:name).sort, Position::DEFAULT_STAGES.sort
    assert_equal position.recruiter, actor_account.member
  end
end
