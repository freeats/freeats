# frozen_string_literal: true

require "test_helper"

class CandidateTest < ActiveSupport::TestCase
  test "should assign a source" do
    candidate = candidates(:john)
    candidate.update!(candidate_source: candidate_sources(:linkedin))

    assert_equal candidate.candidate_source, candidate_sources(:linkedin)
  end
end
