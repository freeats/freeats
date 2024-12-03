# frozen_string_literal: true

require "test_helper"

class Candidates::UploadFileTest < ActionDispatch::IntegrationTest
  setup do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)

    @empty_pdf_file = ActionDispatch::Http::UploadedFile.new(
      filename: "empty.pdf",
      type: "application/pdf",
      tempfile: Rails.root.join("test/fixtures/files/empty.pdf")
    )

    @not_empty_pdf_file = ActionDispatch::Http::UploadedFile.new(
      filename: "cv_with_links.pdf",
      type: "application/pdf",
      tempfile: Rails.root.join("test/fixtures/files/cv_with_links.pdf")
    )
  end

  test "should set source and text_checksum metadata when we upload a pdf file" do
    candidate = candidates(:sam)

    assert_equal candidate.files.size, 0

    Candidates::UploadFile.new(
      candidate:,
      file: @empty_pdf_file,
      source: "linkedin",
      namespace: :api
    ).call.value!

    candidate.reload

    assert_equal candidate.files.size, 1

    file = candidate.files.first

    assert_predicate file.blob.custom_metadata[:text_checksum], :present?
    assert_equal file.blob.custom_metadata[:source], "linkedin"
  end

  test "should not set source and text_checksum metadata when we upload non-pdf file" do
    candidate = candidates(:sam)

    assert_equal candidate.files.size, 0

    file = ActionDispatch::Http::UploadedFile.new(
      filename: "icon.jpg",
      type: "image/jpeg",
      tempfile: Rails.root.join("test/fixtures/files/icon.jpg")
    )

    Candidates::UploadFile.new(
      candidate:,
      file:,
      source: "linkedin",
      namespace: :api
    ).call.value!

    candidate.reload

    assert_equal candidate.files.size, 1

    file = candidate.files.first

    assert_nil file.blob.custom_metadata[:text_checksum]
    assert_nil file.blob.custom_metadata[:source]
  end

  test "should mark the file as cv when we upload a pdf file with cv flag and the candidate did not have cv " \
       "or existing cv is from the same source" do
    candidate = candidates(:sam)

    assert_nil candidate.cv

    Candidates::UploadFile.new(
      candidate:,
      file: @empty_pdf_file,
      cv: true,
      source: "linkedin",
      namespace: :api
    ).call.value!

    candidate.reload

    old_cv = candidate.cv

    assert_predicate old_cv, :present?

    Candidates::UploadFile.new(
      candidate:,
      file: @not_empty_pdf_file,
      cv: true,
      source: "linkedin",
      namespace: :api
    ).call.value!

    candidate.reload

    new_cv = candidate.cv

    assert_predicate new_cv, :present?
    assert_not_equal old_cv, new_cv
    assert_equal candidate.files.size, 2
  end

  test "should not mark the file as cv when we upload a pdf file with cv flag via api " \
       "and the candidate has a cv from another source" do
    candidate = candidates(:sam)

    assert_nil candidate.cv

    Candidates::UploadFile.new(
      candidate:,
      file: @empty_pdf_file,
      cv: true,
      source: "reed",
      namespace: :api
    ).call.value!

    candidate.reload

    old_cv = candidate.cv

    assert_predicate old_cv, :present?

    Candidates::UploadFile.new(
      candidate:,
      file: @not_empty_pdf_file,
      cv: true,
      source: "linkedin",
      namespace: :api
    ).call.value!

    candidate.reload

    new_cv = candidate.cv

    assert_predicate new_cv, :present?
    assert_equal old_cv, new_cv
    assert_equal candidate.files.size, 2

    file1_metadata = candidate.files.first.blob.custom_metadata
    file2_metadata = candidate.files.second.blob.custom_metadata

    assert_not_equal file1_metadata[:source], file2_metadata[:source]
    assert_not_equal file1_metadata[:text_checksum], file2_metadata[:text_checksum]
  end

  test "should mark the file as cv when we upload a pdf file with cv flag via ats " \
       "and the candidate has a cv from another source" do
    candidate = candidates(:sam)

    assert_nil candidate.cv

    Candidates::UploadFile.new(
      candidate:,
      file: @empty_pdf_file,
      cv: true,
      source: "reed",
      namespace: :api
    ).call.value!

    candidate.reload

    old_cv = candidate.cv

    assert_predicate old_cv, :present?

    Candidates::UploadFile.new(
      candidate:,
      file: @not_empty_pdf_file,
      cv: true,
      namespace: :ats
    ).call.value!

    candidate.reload

    new_cv = candidate.cv

    assert_predicate new_cv, :present?
    assert_not_equal old_cv, new_cv
    assert_equal candidate.files.size, 2

    file1_metadata = candidate.files.first.blob.custom_metadata
    file2_metadata = candidate.files.second.blob.custom_metadata

    assert_not_equal file1_metadata[:source], file2_metadata[:source]
    assert_not_equal file1_metadata[:text_checksum], file2_metadata[:text_checksum]
  end

  test "should not allow to upload the same pdf file twice" do
    candidate = candidates(:sam)

    assert_equal candidate.files.size, 0

    Candidates::UploadFile.new(candidate:, file: @empty_pdf_file, namespace: :ats, cv: true).call.value!

    candidate.reload

    assert_equal candidate.files.size, 1
    assert_predicate candidate.cv, :present?

    result = Candidates::UploadFile.new(candidate:, file: @empty_pdf_file, namespace: :ats, cv: true).call

    assert_equal result, Failure(:file_already_present)

    candidate.reload

    assert_equal candidate.files.size, 1
    assert_predicate candidate.cv, :present?
  end

  test "should allow to upload the same non-pdf file twice" do
    candidate = candidates(:sam)

    assert_equal candidate.files.size, 0

    file = ActionDispatch::Http::UploadedFile.new(
      filename: "icon.jpg",
      type: "image/jpeg",
      tempfile: Rails.root.join("test/fixtures/files/icon.jpg")
    )

    Candidates::UploadFile.new(candidate:, file:, namespace: :ats).call.value!

    candidate.reload

    assert_equal candidate.files.size, 1

    Candidates::UploadFile.new(candidate:, file:, namespace: :ats).call.value!

    candidate.reload

    assert_equal candidate.files.size, 2
  end
end
