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

    duplicate_by_phone = candidates(:ivan)
    duplicate_by_phone.phones = [phone.slice(:phone, :type, :status)]

    assert_equal candidate.duplicates.sort,
                 [duplicate_by_email, duplicate_by_link, duplicate_by_phone].sort
  end

  test "should not show duplicates for a person with same invalid phone/email" do
    candidate = candidates(:jane)

    assert_empty candidate.duplicates

    same_invalid_email = { address: candidate.candidate_emails.first,
                           type: :personal,
                           status: :invalid }
    same_invalid_phone = { phone: candidate.phones.first, status: :invalid, type: :personal }

    duplicate_with_same_invalid_email = candidates(:ivan)
    duplicate_with_same_invalid_email.emails = [same_invalid_email]

    duplicates_with_same_invalid_phone = candidates(:sam)
    duplicates_with_same_invalid_phone.phones = [same_invalid_phone]

    assert_empty candidate.duplicates
  end

  test "should stop sequences with specified status" do
    candidate = candidates(:sam)
    sequence = sequences(:ruby_position_sam)

    assert_equal sequence.status, "running"

    Candidates::StopSequences.new(candidate:, with_status: :replied, with_exited_at: 1.hour.ago).call.value!

    assert_equal sequence.reload.status, "replied"
  end
end
