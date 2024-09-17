# frozen_string_literal: true

require "test_helper"

class ActiveStorage::AttachmentTest < ActiveSupport::TestCase
  test "should delete additional_information and blob after deleting attachment" do
    candidate = candidates(:john)

    assert_equal candidate.files.count, 0
    assert_equal AttachmentInformation.count, 0

    Rails.root.join("test/fixtures/files/empty.pdf").open do |file|
      candidate.files.attach(file)
    end

    attachment = candidate.files.first

    additional_information =
      AttachmentInformation.find_or_initialize_by(active_storage_attachment_id: attachment.id)

    additional_information.is_cv = true
    additional_information.save!

    assert_equal candidate.files.count, 1
    assert_equal AttachmentInformation.count, 1

    attachment.remove

    assert_equal candidate.files.count, 0
    assert_equal AttachmentInformation.count, 0
    assert_nil ActiveStorage::Blob.find_by(id: attachment.blob_id)
  end

  test "should delete additional_information and keep blob after deleting attachment" do
    candidate1 = candidates(:john)
    candidate2 = candidates(:jake)

    assert_equal candidate1.files.count, 0
    assert_equal candidate2.files.count, 0
    assert_equal AttachmentInformation.count, 0

    Rails.root.join("test/fixtures/files/empty.pdf").open do |file|
      candidate1.files.attach(file)
    end
    attachment1 = candidate1.files.first
    candidate2.files.attach(attachment1.blob)

    assert_equal candidate1.files.first.blob, candidate2.files.first.blob

    additional_information =
      AttachmentInformation.find_or_initialize_by(active_storage_attachment_id: attachment1.id)

    additional_information.is_cv = true
    additional_information.save!

    assert_equal candidate1.files.count, 1
    assert_equal candidate2.files.count, 1
    assert_equal AttachmentInformation.count, 1

    attachment1.remove

    assert_equal candidate1.files.count, 0
    assert_equal candidate2.files.count, 1
    assert_equal AttachmentInformation.count, 0
    assert_not_nil ActiveStorage::Blob.find_by(id: attachment1.blob_id)
  end
end
