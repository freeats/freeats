# frozen_string_literal: true

require "test_helper"

class CandidateTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  test "should assign a source" do
    candidate = candidates(:john)
    candidate.update!(candidate_source: candidate_sources(:linkedin))

    assert_equal candidate.candidate_source, candidate_sources(:linkedin)
  end

  test "should return all duplicates" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    candidate = candidates(:john)
    candidates(:john_duplicate).destroy!
    email_address = candidate.candidate_email_addresses.first
    phone = candidate.candidate_phones.first
    link = "https://www.linkedin.com/in/awesome_linkedin_profile/"

    # candidate's link and phone are not normalized.
    candidate.links = [{ url: link, status: "current" }]
    candidate.phones = [phone.slice(:phone, :type, :status)]

    assert_equal email_address.status, "current"
    assert_equal phone.status, "current"
    assert_equal phone.type, "personal"
    assert_empty candidate.duplicates

    duplicate_by_email = candidates(:jane)
    duplicate_by_email.emails = [email_address.slice(:address, :type, :status)]

    assert_equal candidate.duplicates, [duplicate_by_email]

    duplicate_by_link = candidates(:sam)
    duplicate_by_link.links = [{ url: link, status: "current" }]

    assert_equal candidate.duplicates.sort, [duplicate_by_email, duplicate_by_link].sort

    duplicate_by_phone = candidates(:jake)
    duplicate_by_phone.phones = [phone.slice(:phone, :type, :status)]

    assert_equal candidate.duplicates.sort,
                 [duplicate_by_email, duplicate_by_link, duplicate_by_phone].sort
  end

  test "should not show duplicates for a person with same invalid phone/email" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    candidate = candidates(:jane)

    assert_empty candidate.duplicates

    same_invalid_email = { address: candidate.candidate_emails.first,
                           type: :personal,
                           status: :invalid }
    same_invalid_phone = { phone: candidate.phones.first, status: :invalid, type: :personal }

    duplicate_with_same_invalid_email = candidates(:jake)
    duplicate_with_same_invalid_email.emails = [same_invalid_email]

    duplicates_with_same_invalid_phone = candidates(:sam)
    duplicates_with_same_invalid_phone.phones = [same_invalid_phone]

    assert_empty candidate.duplicates
  end

  test "positions_for_quick_assignment should suggest a position " \
       "where current member is a recruiter" do
    current_member = members(:admin_member)
    candidate = candidates(:jake)
    position = positions(:ruby_position)

    assert_empty position.collaborators
    assert_equal position.recruiter, current_member
    assert_equal candidate.positions_for_quick_assignment(current_member.id), [position]
  end

  test "positions_for_quick_assignment should suggest a position " \
       "where current member is a collaborator" do
    current_member = members(:employee_member)
    candidate = candidates(:jane)
    position = positions(:ruby_position)

    assert_empty candidate.positions_for_quick_assignment(current_member.id)

    position.collaborators = [members(:helen_member)]

    assert_empty candidate.positions_for_quick_assignment(current_member.id)

    position.collaborators = [current_member]

    assert_equal candidate.positions_for_quick_assignment(current_member.id), [position]
  end

  test "positions_for_quick_assignment should not suggest a position " \
       "if a candidate is already placed on it" do
    tenant = tenants(:toughbyte_tenant)
    current_member = members(:admin_member)
    candidate = candidates(:jake)
    position = positions(:ruby_position)

    assert_equal candidate.positions_for_quick_assignment(current_member.id), [position]

    create(:placement, candidate:, position:, position_stage: position.stages.first, tenant:)

    assert_empty candidate.positions_for_quick_assignment(current_member.id)
  end
end
