# frozen_string_literal: true

require "test_helper"

class API::V1::DocumentsControllerTest < ActionDispatch::IntegrationTest
  test "should create candidate" do
    sign_in accounts(:admin_account)

    url = "https://www.linkedin.com/in/username/"
    full_name = "Sam Smith"
    cv = fixture_file_upload("empty.pdf", "application/pdf")

    assert_difference "Candidate.count" do
      post api_v1_candidates_url, params: { url:, full_name:, cv: }
    end

    candidate = Candidate.last

    assert_equal candidate.full_name, full_name
    assert_equal candidate.links, [url]
    assert_equal candidate.source, "LinkedIn"
  end

  test "should not update candidate's source if it is already set and update if not" do
    sign_in accounts(:admin_account)

    candidate = candidates(:sam)
    url = candidate_links(:sam_link).url
    cv = fixture_file_upload("empty.pdf", "application/pdf")

    assert_equal candidate.source, "HeadHunter"
    assert_match %r{^https://www\.linkedin\.com/in}, url
    assert_equal candidate.files.size, 0

    post api_v1_candidates_url, params: { url:, cv:, full_name: candidate.full_name }

    candidate.reload

    assert_equal candidate.files.size, 1
    assert_equal candidate.source, "HeadHunter"

    candidate.update!(source: nil)

    post api_v1_candidates_url, params: { url:, cv:, full_name: candidate.full_name }

    candidate.reload

    assert_equal candidate.files.size, 2
    assert_equal candidate.source, "LinkedIn"
  end
end
