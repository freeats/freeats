# frozen_string_literal: true

require "test_helper"

class PlacementTest < ActiveSupport::TestCase
  test "should create placement" do
    candidate = candidates(:john)
    position = positions(:ruby_position)
    sourced_position_stage = position_stages(:ruby_position_sourced)

    placement = Placements::Add.new(params: { candidate: }, position:).call.value!

    assert_equal placement.position_stage_id, sourced_position_stage.id
  end
end
