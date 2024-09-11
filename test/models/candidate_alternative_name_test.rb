# frozen_string_literal: true

require "test_helper"

class CandidateAlternativeNameTest < ActiveSupport::TestCase
  test "should collapse spaces" do
    alt_name = CandidateAlternativeName.create!(
      candidate: candidates(:john),
      name: "name    with   a lot of     spaces",
      tenant: tenants(:toughbyte_tenant)
    )

    assert_equal alt_name.name, "name with a lot of spaces"
  end
end
