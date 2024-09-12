# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/imap/imap_test_helper"

class EmailSynchronization::SynchronizeTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  ITH = ImapTestHelper

  test "should work with only_for_email_addresses" do
    message_list = [ITH::PARSED_CANDIDATE_MESSAGE, ITH::PARSED_SIMPLE_MESSAGE]
    only_for_email_addresses = ["test@gmail.com"]

    oauth_client_mock = Minitest::Mock.new
    oauth_client_mock.expect :fetch_access_token!, true
    oauth_client_mock.expect :access_token, "token"

    imap_account = nil
    Gmail::Auth.stub :with_tokens, oauth_client_mock do
      imap_account = members(:admin_member).imap_account
    end

    message_mock = Minitest::Mock.new
    message_mock.expect(
      :call,
      [message_list],
      [only_for_email_addresses],
      from_account: imap_account,
      batch_size: EmailSynchronization::Synchronize::BATCH_SIZE
    )

    postprocess_mock = Minitest::Mock.new
    postprocess_mock.expect(:call, nil, [imap_account])

    Member.stub(:postprocess_imap_account, postprocess_mock) do
      Imap::Message.stub(:message_batches_related_to, message_mock) do
        result = EmailSynchronization::Synchronize.new(
          imap_account:,
          only_for_email_addresses:
        ).call

        assert_equal result, Success()
      end
    end
  end

  test "should work without only_for_email_addresses" do
    message_list = [ITH::PARSED_CANDIDATE_MESSAGE, ITH::PARSED_SIMPLE_MESSAGE]

    oauth_client_mock = Minitest::Mock.new
    oauth_client_mock.expect :fetch_access_token!, true
    oauth_client_mock.expect :access_token, "token"

    imap_account = nil
    Gmail::Auth.stub :with_tokens, oauth_client_mock do
      imap_account = members(:admin_member).imap_account
    end

    message_mock = Minitest::Mock.new
    message_mock.expect(
      :call,
      [message_list],
      [],
      from_account: imap_account,
      batch_size: EmailSynchronization::Synchronize::BATCH_SIZE
    )

    postprocess_mock = Minitest::Mock.new
    postprocess_mock.expect(:call, nil, [imap_account])

    Member.stub(:postprocess_imap_account, postprocess_mock) do
      Imap::Message.stub(:new_message_batches, message_mock) do
        result = EmailSynchronization::Synchronize.new(
          imap_account:
        ).call

        assert_equal result, Success()
      end
    end
  end
end
