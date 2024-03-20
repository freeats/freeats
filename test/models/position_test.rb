# frozen_string_literal: true

require "test_helper"

class PositionTest < ActiveSupport::TestCase
  test "should create position" do
    Position.create!(
      name: "Ruby developer",
      status: :active,
      change_status_reason: :other
    )
  end
end
