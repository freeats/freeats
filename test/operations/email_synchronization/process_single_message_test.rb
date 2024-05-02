# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/imap/imap_test_helper"

class EmailSynchronization::ProcessSingleMessageTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  ITH = ImapTestHelper

  test "should work" do
    result = EmailSynchronization::ProcessSingleMessage.new(
      message: ITH::PARSED_CANDIDATE_MESSAGE
    ).call

    assert_equal result, Success()
  end

  test "upload attachments should work" do
    raw_message = ITH::MESSAGE_WITH_ATTACHMENT.tap do |msg|
      msg.from = [candidate_email_addresses(:john_email_address).address]
      msg.to = ["admin@admin.com"]
    end
    message = Imap::Message.new_from_api(
      raw_message,
      ITH::MESSAGE_UID,
      ITH::MESSAGE_FLAGS
    )
    result = EmailSynchronization::ProcessSingleMessage.new(
      message:
    ).call

    assert_equal result, Success()
  end

  test "shouldn't work if message without address from db" do
    raw_message = ITH::MESSAGE_WITH_ATTACHMENT.tap do |msg|
      msg.from = ["unknown@gmail.com"]
      msg.to = ["admin@admin.com"]
    end
    message = Imap::Message.new_from_api(
      raw_message,
      ITH::MESSAGE_UID,
      ITH::MESSAGE_FLAGS
    )
    result = EmailSynchronization::ProcessSingleMessage.new(
      message:
    ).call

    assert_equal result, Failure(:not_relevant_message)
  end

  test "shouldn't work if message without member address" do
    raw_message = ITH::MESSAGE_WITH_ATTACHMENT.tap do |msg|
      msg.from = [candidate_email_addresses(:john_email_address).address]
      msg.to = ["dmitry.matveyev@gmail.com"]
    end
    message = Imap::Message.new_from_api(
      raw_message,
      ITH::MESSAGE_UID,
      ITH::MESSAGE_FLAGS
    )
    result = EmailSynchronization::ProcessSingleMessage.new(
      message:
    ).call

    assert_equal result, Failure(:message_does_not_contain_member_email_addresses)
  end

  test "shouldn't process if message with service address" do
    message = Imap::Message.new_from_api(
      ITH::MESSAGE_WITH_SERVICE_ADDRESS,
      ITH::MESSAGE_UID,
      ITH::MESSAGE_FLAGS
    )
    result = EmailSynchronization::ProcessSingleMessage.new(
      message:
    ).call

    assert_equal result, Failure(:not_relevant_message)
  end
end
