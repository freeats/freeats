# frozen_string_literal: true

require "test_helper"

class ATS::PositionsGridTest < ActiveSupport::TestCase
  test "name filter should work" do
    relevant_position = positions(:ruby_position)
    other_position = positions(:golang_position)

    grid_assets =
      ATS::PositionsGrid.new(name: relevant_position.name[0..7]).assets.to_a

    assert_includes grid_assets, relevant_position
    assert_not_includes grid_assets, other_position
  end

  test "location filter should work" do
    position_with_location = positions(:ruby_position)
    position_without_location = positions(:golang_position)

    assert position_with_location.location
    assert_nil position_without_location.location

    grid_assets =
      ATS::PositionsGrid.new(locations: [position_with_location.location_id]).assets.to_a

    assert_includes grid_assets, position_with_location
    assert_not_includes grid_assets, position_without_location
  end

  test "status filter should work" do
    closed_position = positions(:closed_position)
    active_position = positions(:golang_position)

    grid_assets =
      ATS::PositionsGrid.new(status: closed_position.status).assets.to_a

    assert_includes grid_assets, closed_position
    assert_not_includes grid_assets, active_position
  end

  test "recruiter filter should work" do
    position_with_recruiter = positions(:ruby_position)
    position_without_recruiter = positions(:golang_position)

    grid_assets =
      ATS::PositionsGrid.new(recruiter: position_with_recruiter.recruiter_id).assets.to_a

    assert_includes grid_assets, position_with_recruiter
    assert_not_includes grid_assets, position_without_recruiter
  end

  test "collaborators filter should work" do
    position_with_collaborators = positions(:ruby_position)
    position_without_collaborators = positions(:golang_position)
    collaborator = members(:employee_member)

    position_with_collaborators.update!(collaborators: [collaborator])

    assert_empty position_without_collaborators.collaborators

    grid_assets =
      ATS::PositionsGrid.new(collaborators: collaborator.id).assets.to_a

    assert_includes grid_assets, position_with_collaborators
    assert_not_includes grid_assets, position_without_collaborators
  end

  test "hiring_managers filter should work" do
    position_without_hiring_managers = positions(:ruby_position)
    position_with_hiring_managers = positions(:golang_position)

    assert_empty position_without_hiring_managers.hiring_managers
    assert_not_empty position_with_hiring_managers.hiring_managers

    grid_assets =
      ATS::PositionsGrid.new(hiring_managers: position_with_hiring_managers.hiring_managers.first.id).assets.to_a

    assert_includes grid_assets, position_with_hiring_managers
    assert_not_includes grid_assets, position_without_hiring_managers
  end
end
