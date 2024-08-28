# frozen_string_literal: true

require "test_helper"

class ATS::CandidatePolicyTest < ActiveSupport::TestCase
  test "should allow hiring_manager to visit candidate's page if candidate is assigned " \
       "to a position where hiring_manager is in hiring_managers or interviewers list" do
    hiring_manager = members(:hiring_manager_member)
    interviewer = members(:interviewer_member)
    candidate = candidates(:john)
    position = positions(:ruby_position)
    actor_account = accounts(:hiring_manager_account)

    assert_includes candidate.placements.map { _1.position.id }, position.id
    assert_empty position.hiring_managers
    assert_empty position.interviewers

    assert_not create_policy(candidate, actor_account, hiring_manager).apply(:show?)

    position.update!(hiring_managers: [hiring_manager])

    assert create_policy(candidate, actor_account, hiring_manager).apply(:show?)

    position.update!(hiring_managers: [], interviewers: [hiring_manager])

    assert create_policy(candidate, actor_account, hiring_manager).apply(:show?)

    position.update!(hiring_managers: [hiring_manager], interviewers: [hiring_manager, interviewer])

    assert create_policy(candidate, actor_account, hiring_manager).apply(:show?)

    position.update!(hiring_managers: [], interviewers: [interviewer])

    assert_not create_policy(candidate, actor_account, hiring_manager).apply(:show?)
  end

  test "should allow interviewer to visit candidate's page if candidate is assigned " \
       "to a position where interviewer is in interviewers list" do
    hiring_manager = members(:hiring_manager_member)
    interviewer = members(:interviewer_member)
    candidate = candidates(:sam)
    position = positions(:golang_position)
    actor_account = accounts(:interviewer_account)

    assert_includes candidate.placements.map { _1.position.id }, position.id
    assert_includes position.hiring_managers, hiring_manager
    assert_empty position.interviewers

    assert_not create_policy(candidate, actor_account, interviewer).apply(:show?)

    position.update!(hiring_managers: [])

    assert_not create_policy(candidate, actor_account, interviewer).apply(:show?)

    position.update!(interviewers: [hiring_manager])

    assert_not create_policy(candidate, actor_account, interviewer).apply(:show?)

    position.update!(hiring_managers: [hiring_manager], interviewers: [hiring_manager, interviewer])

    assert create_policy(candidate, actor_account, interviewer).apply(:show?)

    position.update!(hiring_managers: [], interviewers: [interviewer])

    assert create_policy(candidate, actor_account, interviewer).apply(:show?)
  end

  private

  def create_policy(candidate, account, member)
    ATS::CandidatePolicy.new(candidate, user: account, member:)
  end
end
