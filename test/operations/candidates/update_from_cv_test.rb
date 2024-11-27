# frozen_string_literal: true

require "test_helper"

class Candidates::UpdateFromCVTest < ActionDispatch::IntegrationTest
  test "should update nothing from empty file" do
    candidate = candidates(:john)
    old_links = candidate.links
    old_phones = candidate.phones
    old_emails = candidate.all_emails

    cv_file = ActionDispatch::Http::UploadedFile.new(
      {
        filename: "empty.pdf",
        type: "application/pdf",
        tempfile: File.new(Rails.root.join("test/fixtures/files/empty.pdf").to_s)
      }
    )

    Candidates::UpdateFromCV.new(cv_file:, candidate:).call.value!

    candidate.reload

    assert_equal candidate.phones, old_phones
    assert_equal candidate.all_emails, old_emails
    assert_equal candidate.links.sort, old_links.sort
  end

  test "should return failure and not update contact info if provided cv_file " \
       "has format different from pdf" do
    candidate = candidates(:jake)
    old_links = candidate.links
    old_phones = candidate.phones
    old_emails = candidate.all_emails
    cv_file = ActionDispatch::Http::UploadedFile.new(
      {
        filename: "john_msg1.txt",
        type: "text/plain",
        tempfile: File.new(Rails.root.join("test/fixtures/files/john_msg1.txt").to_s)
      }
    )

    result = Candidates::UpdateFromCV.new(cv_file:, candidate:).call

    assert_predicate result, :failure?
    assert_equal candidate.phones, old_phones
    assert_equal candidate.all_emails, old_emails
    assert_equal candidate.links.sort, old_links.sort
  end

  test "should return failure and not update contact info if one of the errors is raised:" \
       "PDF::Reader::MalformedPDFError, PDF::Reader::InvalidPageError, CVParser::CVParserError" do
    candidate = candidates(:jake)
    old_links = candidate.links
    old_phones = candidate.phones
    old_emails = candidate.all_emails
    cv_file = ActionDispatch::Http::UploadedFile.new(
      {
        filename: "cv_with_links.pdf",
        type: "application/pdf",
        tempfile: File.new(Rails.root.join("test/fixtures/files/cv_with_links.pdf").to_s)
      }
    )

    result =
      CVParser::Parser.stub :parse_pdf, ->(*) { raise CVParser::CVParserError } do
        Candidates::UpdateFromCV.new(cv_file:, candidate:).call
      end

    assert_predicate result, :failure?
    assert_equal candidate.phones, old_phones
    assert_equal candidate.all_emails, old_emails
    assert_equal candidate.links.sort, old_links.sort
  end

  test "should return failure and not update contact info if Candidates::Change returns failure" do
    candidate = candidates(:jake)
    old_links = candidate.links
    old_phones = candidate.phones
    old_emails = candidate.all_emails
    cv_file = ActionDispatch::Http::UploadedFile.new(
      {
        filename: "cv_with_links.pdf",
        type: "application/pdf",
        tempfile: File.new(Rails.root.join("test/fixtures/files/cv_with_links.pdf").to_s)
      }
    )

    candidate_change_mock = Minitest::Mock.new
    candidate_change_mock.expect(:call, Failure[:candidate_invalid, nil], [])

    result =
      Candidates::Change.stub :new, ->(*) { candidate_change_mock } do
        Candidates::UpdateFromCV.new(cv_file:, candidate:).call
      end

    assert_predicate result, :failure?
    assert_equal candidate.phones, old_phones
    assert_equal candidate.all_emails, old_emails
    assert_equal candidate.links.sort, old_links.sort
  end
end
