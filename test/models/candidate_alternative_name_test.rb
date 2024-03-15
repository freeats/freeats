# frozen_string_literal: true

require "test_helper"

class CandidateAlternativeNameTest < ActiveSupport::TestCase
  test "should collapse spaces" do
    alt_name = CandidateAlternativeName.create!(
      candidate: candidates(:john),
      name: "name    with   a lot of     spaces"
    )

    assert_equal alt_name.name, "name with a lot of spaces"
  end

  test "should convert empty name to nil" do
    assert_raise ActiveRecord::NotNullViolation do
      CandidateAlternativeName.create!(
        candidate: candidates(:john),
        name: ""
      )
    end
  end
end
