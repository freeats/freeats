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

  test "include_blacklisted filter should work" do
    candidate = candidates(:john)
    blacklisted_candidate = candidates(:john_duplicate)

    grid_assets = ATS::CandidatesGrid.new(include_blacklisted: ["true"]).assets.to_a

    assert_includes grid_assets, candidate
    assert_includes grid_assets, blacklisted_candidate

    grid_assets = ATS::CandidatesGrid.new(include_blacklisted: ["false"]).assets.to_a

    assert_not_includes grid_assets, blacklisted_candidate
    assert_includes grid_assets, candidate
  end

  test "recruiter filter should work" do
    unassigned_candidate = candidates(:jane)
    assigned_candidate = candidates(:sam)
    recruiter = members(:admin_member)

    grid_assets = ATS::CandidatesGrid.new.assets.to_a

    assert_includes grid_assets, unassigned_candidate
    assert_includes grid_assets, assigned_candidate

    grid_assets = ATS::CandidatesGrid.new(recruiter: recruiter.id).assets.to_a

    assert_not_includes grid_assets, unassigned_candidate
    assert_includes grid_assets, assigned_candidate
  end

  test "position, stage, status filters should work" do
    candidate_without_placements = candidates(:jane)
    candidate_with_ruby_placement = candidates(:john)
    candidate_with_goland_placement = candidates(:ivan)
    candidate_with_both_placements = candidates(:sam)
    golang_position = positions(:golang_position)
    ruby_position = positions(:ruby_position)

    grid_assets = ATS::CandidatesGrid.new.assets.to_a

    assert_includes grid_assets, candidate_without_placements
    assert_includes grid_assets, candidate_with_ruby_placement
    assert_includes grid_assets, candidate_with_goland_placement
    assert_includes grid_assets, candidate_with_both_placements

    grid_assets = ATS::CandidatesGrid.new(position: ruby_position.id).assets.to_a

    assert_not_includes grid_assets, candidate_without_placements
    assert_includes grid_assets, candidate_with_ruby_placement
    assert_not_includes grid_assets, candidate_with_goland_placement
    assert_includes grid_assets, candidate_with_both_placements

    # position, status and stage filters are dependent,
    # i.e. if all status, stage and position filter are specified only candidates who
    # have placements on the selected position on selected stages
    # with selected status should be returned
    grid_assets =
      ATS::CandidatesGrid.new(position: golang_position.id, stage: %w[Sourced Hired]).assets.to_a

    assert_not_includes grid_assets, candidate_without_placements
    assert_not_includes grid_assets, candidate_with_ruby_placement
    assert_includes grid_assets, candidate_with_goland_placement
    assert_includes grid_assets, candidate_with_both_placements

    grid_assets =
      ATS::CandidatesGrid.new(stage: %w[Sourced Hired]).assets.to_a

    assert_not_includes grid_assets, candidate_without_placements
    assert_includes grid_assets, candidate_with_ruby_placement
    assert_includes grid_assets, candidate_with_goland_placement
    assert_includes grid_assets, candidate_with_both_placements

    grid_assets =
      ATS::CandidatesGrid.new(
        position: golang_position.id,
        stage: %w[Sourced Hired],
        status: "no_reply"
      ).assets.to_a

    assert_not_includes grid_assets, candidate_without_placements
    assert_not_includes grid_assets, candidate_with_ruby_placement
    assert_not_includes grid_assets, candidate_with_goland_placement
    assert_includes grid_assets, candidate_with_both_placements

    grid_assets =
      ATS::CandidatesGrid.new(
        position: golang_position.id,
        stage: %w[Sourced Hired],
        status: "qualified"
      ).assets.to_a

    assert_not_includes grid_assets, candidate_without_placements
    assert_not_includes grid_assets, candidate_with_ruby_placement
    assert_includes grid_assets, candidate_with_goland_placement
    assert_not_includes grid_assets, candidate_with_both_placements

    grid_assets =
      ATS::CandidatesGrid.new(
        stage: %w[Sourced Hired],
        status: "qualified"
      ).assets.to_a

    assert_not_includes grid_assets, candidate_without_placements
    assert_includes grid_assets, candidate_with_ruby_placement
    assert_includes grid_assets, candidate_with_goland_placement
    assert_not_includes grid_assets, candidate_with_both_placements

    grid_assets =
      ATS::CandidatesGrid.new(
        status: "qualified"
      ).assets.to_a

    assert_not_includes grid_assets, candidate_without_placements
    assert_includes grid_assets, candidate_with_ruby_placement
    assert_includes grid_assets, candidate_with_goland_placement
    assert_includes grid_assets, candidate_with_both_placements
  end
end
