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

    imap_accounts = nil
    Gmail::Auth.stub :with_tokens, oauth_client_mock do
      imap_accounts = [member_email_addresses(:admin_first_email_address).imap_account]
    end

    message_mock = Minitest::Mock.new
    message_mock.expect(
      :call,
      [message_list],
      [only_for_email_addresses],
      from_accounts: imap_accounts,
      batch_size: EmailSynchronization::Synchronize::BATCH_SIZE
    )

    postprocess_mock = Minitest::Mock.new
    postprocess_mock.expect(:call, nil, [imap_accounts])

    Member::EmailAddress.stub(:postprocess_imap_accounts, postprocess_mock) do
      Imap::Message.stub(:message_batches_related_to, message_mock) do
        result = EmailSynchronization::Synchronize.new(
          imap_accounts:,
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

    imap_accounts = nil
    Gmail::Auth.stub :with_tokens, oauth_client_mock do
      imap_accounts = [member_email_addresses(:admin_first_email_address).imap_account]
    end

    message_mock = Minitest::Mock.new
    message_mock.expect(
      :call,
      [message_list],
      [],
      from_accounts: imap_accounts,
      batch_size: EmailSynchronization::Synchronize::BATCH_SIZE
    )

    postprocess_mock = Minitest::Mock.new
    postprocess_mock.expect(:call, nil, [imap_accounts])

    Member::EmailAddress.stub(:postprocess_imap_accounts, postprocess_mock) do
      Imap::Message.stub(:new_message_batches, message_mock) do
        result = EmailSynchronization::Synchronize.new(
          imap_accounts:
        ).call

        assert_equal result, Success()
      end
    end
  end
end
