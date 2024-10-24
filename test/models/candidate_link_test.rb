# frozen_string_literal: true

require "test_helper"

class CandidateLinkTest < ActiveSupport::TestCase
  test "should normalize url during save" do
    candidate_link = CandidateLink.create!(
      candidate: candidates(:john),
      url: "https://github.com/AsdF",
      tenant: tenants(:toughbyte_tenant)
    )

    assert_equal candidate_link.url, "https://github.com/asdf"
  end
end
