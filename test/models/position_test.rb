# frozen_string_literal: true

require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "should create position with default position_stages" do
    params = {
      name: "Ruby    developer    ",
      status: :active,
      change_status_reason: :other
    }
    position = Positions::Add.new(params:).call.value!

    assert_equal position.name, "Ruby developer"
    assert_equal position.stages.pluck(:name).sort, Position::DEFAULT_STAGES.sort
  end
end
