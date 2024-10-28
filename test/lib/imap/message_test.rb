# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "./test/lib/imap/imap_test_helper"

class ImapMessageTest < ActiveSupport::TestCase
  include ImapTestHelper

  ITH = ImapTestHelper

  setup do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
  end

  test "should parse message" do
    message = Imap::Message.new_from_api(ITH::SIMPLE_MESSAGE, MESSAGE_UID, MESSAGE_FLAGS)

    assert_equal message, PARSED_SIMPLE_MESSAGE
  end

  test "should parse message with only html body" do
    message = Imap::Message.new_from_api(ITH::MESSAGE_WITH_ONLY_HTML_BODY, MESSAGE_UID, MESSAGE_FLAGS)

    assert_predicate message.plain_body, :blank?
    assert_predicate message.plain_mime_type, :blank?
    assert_predicate message.html_body, :present?
  end

  test "should parse message with only plain body" do
    message = Imap::Message.new_from_api(ITH::MESSAGE_WITH_ONLY_PLAIN_BODY, MESSAGE_UID, MESSAGE_FLAGS)

    assert_predicate message.plain_body, :present?
    assert_equal message.plain_mime_type, "text/plain"
    assert_predicate message.html_body, :blank?
  end

  test "should parse message with multiple addresses" do
    message = Imap::Message.new_from_api(ITH::MESSAGE_WITH_MULTIPLE_ADDRESSES, MESSAGE_UID, MESSAGE_FLAGS)

    assert_equal message.to.sort,
                 ["larry.grant@example.com", "Arthur Morgan <arthur.morgan@example.com>"].sort
    assert_equal message.clean_to_emails.sort,
                 ["larry.grant@example.com", "arthur.morgan@example.com"].sort

    assert_equal message.to.map { Imap::Message.parse_address(_1) }.sort_by { _1[:address] },
                 [
                   { name: "", address: "larry.grant@example.com" },
                   { name: "Arthur Morgan", address: "arthur.morgan@example.com" }
                 ].sort_by { _1[:address] }
  end

  test "should parse reply message" do
    message = Imap::Message.new_from_api(ITH::REPLY_TO_MESSAGE, MESSAGE_UID, MESSAGE_FLAGS)

    assert_equal message.in_reply_to, "<EC9C7AF8-CC38-4407-AEC9-8751A3229700@gmail.com>"
    assert_equal message.references, ["<EC9C7AF8-CC38-4407-AEC9-8751A3229700@gmail.com>"]
  end

  test "should parse auto-reply message" do
    message = Imap::Message.new_from_api(ITH::AUTO_REPLY_MESSAGE, MESSAGE_UID, MESSAGE_FLAGS)

    assert_predicate message, :auto_replied?
  end

  test "should parse message attachments" do
    message = Imap::Message.new_from_api(ITH::MESSAGE_WITH_ATTACHMENT, MESSAGE_UID, MESSAGE_FLAGS)

    assert_predicate message.attachments, :present?
  end

  test "should parse message and decode name" do
    message = Imap::Message.new_from_api(
      ITH::MESSAGE_WITH_ENCODED_NAME, MESSAGE_UID, MESSAGE_FLAGS
    )

    to_field_names =
      Imap::Message.parse_address(message.to.first).values_at(:name)

    from_field_names =
      Imap::Message.parse_address(message.from.first).values_at(:name)

    assert_equal to_field_names, ["Arthur Morgan"]
    assert_equal from_field_names, ["test"]
  end

  test "should parse message with both plain text body and html body" do
    message = Imap::Message.new_from_api(ITH::SIMPLE_MESSAGE, MESSAGE_UID, MESSAGE_FLAGS)

    assert_equal message.to, ["Developers <developers@example.com>"]
    assert_equal message.from, ["Admin Admin <admin@mail.com>"]
    assert_equal message.subject, "Report for 25.01.24"
    assert_equal message.timestamp, Time.parse("Thu, 25 Jan 2024 07:59:22 +0600").to_i
    assert_equal message.plain_mime_type, "text/plain"
    assert_includes(
      message.plain_body,
      "Software Developer at ACME"
    )
    assert_includes(
      message.html_body,
      "<div style=\"font-size:16px;font-weight:700;line-height:24px\">Stefan Hammond</div>"
    )
  end

  test "should parse message-reply from Hub" do
    message = Imap::Message.new_from_api(ITH::REPLY_FROM_HUB_MESSAGE, MESSAGE_UID, MESSAGE_FLAGS)

    assert_equal message.to, ["test <test@gmail.com>"]
    assert_equal message.from, ["Arthur Morgan <arthur.morgan@example.com>"]
    assert_equal message.subject, "Re: Message with attachment"
    assert_equal message.timestamp, Time.parse("Fri, 26 Jan 2024 07:00:01 -0800").to_i
    assert_equal message.message_id, "<CA+frY=t9OGrwyVD7BzLOAaPQpikk6Cuy1SdH=ApT535PA4H4ug@mail.gmail.com>"
    assert_equal message.in_reply_to, "<CA+frY=tOAEo5BvJQmL82PYdcsXaESRLxufamtT_GBFGjHJtmPA@mail.gmail.com>"
    assert_includes message.html_body, "Reply from hub!"
  end

  test "should parse message with encoded body" do
    message = Imap::Message.new_from_api(ITH::MESSAGE_WITH_ENCODED_BODY, MESSAGE_UID, MESSAGE_FLAGS)

    assert_equal message.plain_body, "encoded message to base64"
  end

  test "should parse message with non utf-8 body and save to db" do
    raw_message = ITH::MESSAGE_WITH_NON_UTF_8_BODY

    message = Imap::Message.new_from_api(raw_message, MESSAGE_UID, MESSAGE_FLAGS)

    assert_nothing_raised do
      EmailMessage.create!(
        email_thread_id: email_threads(:john).id,
        timestamp: message.timestamp,
        subject: message.subject,
        plain_body: message.plain_body,
        plain_mime_type: message.plain_mime_type,
        html_body: message.html_body,
        sent_via: :gmail,
        message_id: message.message_id,
        in_reply_to: message.in_reply_to || "",
        references: message.references || [],
        autoreply_headers: message.autoreply_headers || {}
      )
    end
  end

  test "should parse pkcs7-mime message and save to db" do
    message = Imap::Message.new_from_api(MESSAGE_WITH_PKCS7_BODY, MESSAGE_UID, MESSAGE_FLAGS)

    assert_nothing_raised do
      EmailMessage.create!(
        email_thread_id: email_threads(:john).id,
        timestamp: message.timestamp,
        subject: message.subject,
        plain_body: message.plain_body,
        plain_mime_type: message.plain_mime_type,
        html_body: message.html_body,
        sent_via: :gmail,
        message_id: message.message_id,
        in_reply_to: message.in_reply_to || "",
        references: message.references || [],
        autoreply_headers: message.autoreply_headers || {}
      )
    end
  end

  test "should receive all messages concerning specific emails" do
    account_params = {
      email: "john.founder@example.com",
      access_token: "oauth_access_token",
      refresh_token: "oauth_refresh_token"
    }

    imap_service_mock = Minitest::Mock.new
    imap_service_mock.expect(
      :fetch_all_messages_related_to,
      [ITH::SIMPLE_MESSAGE],
      [%w[travis.hodge@example.com]],
      batch_size: Imap::Account::DEFAULT_BATCH_SIZE
    )

    Imap::Account.stub(:new, imap_service_mock) do
      account = Imap::Account.new(**account_params)

      Imap::Message.message_batches_related_to(
        %w[travis.hodge@example.com],
        from_account: account
      ).each do |message_batch|
        assert_includes message_batch, ITH::SIMPLE_MESSAGE
      end
    end

    imap_service_mock.verify
  end

  test "should receive new messages since the last fetch with last_email_synchronization_uid" do
    account_params = {
      email: "john.founder@example.com",
      access_token: "oauth_access_token",
      refresh_token: "oauth_refresh_token",
      last_email_synchronization_uid: MESSAGE_UID
    }

    freeze_time do
      imap_service_mock = Minitest::Mock.new
      imap_service_mock.expect(:last_email_synchronization_uid, MESSAGE_UID)
      imap_service_mock.expect(
        :fetch_updates,
        [ITH::SIMPLE_MESSAGE],
        batch_size: Imap::Account::DEFAULT_BATCH_SIZE
      )

      Imap::Account.stub(:new, imap_service_mock) do
        account = Imap::Account.new(**account_params)

        Imap::Message.new_message_batches(
          from_account: account
        ).each do |message_batch|
          assert_includes message_batch, ITH::SIMPLE_MESSAGE
        end
      end

      imap_service_mock.verify
    end
  end

  test "should receive new messages since the last fetch without last_email_synchronization_uid" do
    account_params = {
      email: "john.founder@example.com",
      access_token: "oauth_access_token",
      refresh_token: "oauth_refresh_token"
    }

    freeze_time do
      imap_service_mock = Minitest::Mock.new
      imap_service_mock.expect(:last_email_synchronization_uid, nil)
      imap_service_mock.expect(
        :fetch_messages_for_last,
        [ITH::SIMPLE_MESSAGE],
        [10.days.ago],
        batch_size: Imap::Account::DEFAULT_BATCH_SIZE
      )

      Imap::Account.stub(:new, imap_service_mock) do
        account = Imap::Account.new(**account_params)

        Imap::Message.new_message_batches(
          from_account: account
        ).each do |message_batch|
          assert_includes message_batch, ITH::SIMPLE_MESSAGE
        end
      end

      imap_service_mock.verify
    end
  end

  test "should mark unauthenticated accounts" do
    account_params = {
      email: "john.founder@example.com",
      access_token: "oauth_access_token",
      refresh_token: "oauth_refresh_token"
    }

    gmail_auth_mock = Minitest::Mock.new

    5.times do
      gmail_auth_mock.expect(
        :call,
        gmail_auth_mock,
        [account_params[:access_token], account_params[:refresh_token]]
      )
      gmail_auth_mock.expect(:fetch_access_token!, nil) do
        raise Signet::AuthorizationError, "auth error"
      end
    end
    account = nil
    Imap::Account.stub_const(:AUTHORIZATION_RETRY_DELAY, 0) do
      Gmail::Auth.stub(:with_tokens, gmail_auth_mock) do
        account = Imap::Account.new(**account_params)
        account.search([])
      end
    end

    gmail_auth_mock.verify

    assert_equal account.status, :unauthenticated
  end
end
