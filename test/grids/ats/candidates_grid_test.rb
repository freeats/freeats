# frozen_string_literal: true

require "test_helper"

class ATS::CandidatesGridTest < ActiveSupport::TestCase
  test "scope should get not merged candidates" do
    candidate = candidates(:john)
    duplicate_candidate = candidates(:john_duplicate)
    duplicate_candidate.update!(merged_to: candidate.id)

    grid_assets = ATS::CandidatesGrid.new.assets.to_a

    assert_includes grid_assets, candidate
    assert_not_includes grid_assets, duplicate_candidate
  end

  test "candidate filter should work " do
    john_candidate = candidates(:john)
    ivan_candidate = candidates(:ivan)

    # search by part of name
    grid_assets =
      ATS::CandidatesGrid.new(candidate: ivan_candidate.full_name[0..5]).assets.to_a

    assert_includes grid_assets, ivan_candidate
    assert_not_includes grid_assets, john_candidate

    # search by alternative name
    grid_assets =
      ATS::CandidatesGrid.new(candidate: ivan_candidate.candidate_alternative_names.sample.name).assets.to_a

    assert_includes grid_assets, ivan_candidate
    assert_not_includes grid_assets, john_candidate

    # search by email address
    grid_assets =
      ATS::CandidatesGrid.new(candidate: ivan_candidate.candidate_emails.sample).assets.to_a

    assert_includes grid_assets, ivan_candidate
    assert_not_includes grid_assets, john_candidate
  end

  test "locations filter should work" do
    moscow_candidate = candidates(:john)
    moscow_location = locations(:moscow_city)
    dublin_location = locations(:dublin_city)
    dublin_candidate = candidates(:sam)
    haridwar_location = locations(:haridwar_city)
    haridwar_candidate = candidates(:ivan)

    assert_equal moscow_candidate.location_id, moscow_location.id
    assert_equal dublin_candidate.location_id, dublin_location.id
    assert_equal haridwar_candidate.location_id, haridwar_location.id

    # single location
    grid_assets = ATS::CandidatesGrid.new(locations: [dublin_location.id]).assets.to_a

    assert_includes grid_assets, dublin_candidate
    assert_not_includes grid_assets, moscow_candidate
    assert_not_includes grid_assets, haridwar_candidate

    # multiple locations
    grid_assets =
      ATS::CandidatesGrid.new(locations: [dublin_location.id, moscow_location.id]).assets.to_a

    assert_not_includes grid_assets, haridwar_candidate
    assert_includes grid_assets, moscow_candidate
    assert_includes grid_assets, dublin_candidate
  end

  test "skip_blacklisted filter should work" do
    candidate = candidates(:john)
    blacklisted_candidate = candidates(:john_duplicate)

    grid_assets = ATS::CandidatesGrid.new(skip_blacklisted: ["false"]).assets.to_a

    assert_includes grid_assets, candidate
    assert_includes grid_assets, blacklisted_candidate

    grid_assets = ATS::CandidatesGrid.new(skip_blacklisted: ["true"]).assets.to_a

    assert_not_includes grid_assets, blacklisted_candidate
    assert_includes grid_assets, candidate
  end
end
