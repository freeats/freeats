# frozen_string_literal: true

require "test_helper"

class EmailSynchronization::ProcessSingleMessage::CreateFromImapTest < ActiveSupport::TestCase
  include Dry::Monads[:result]
  include ActionMailer::TestHelper

  setup do
    @tested_class = EmailSynchronization::ProcessSingleMessage::CreateFromImap
  end

  test "should normalize addresses before create" do
    to_addresses = ["<john.founder@toughbyte.com>",
                    "Admin <admin@toughbyte.com>",
                    "<Sergey Tomashevsky> <sergey.tomashevsky@toughbyte.com>",
                    "\"<Alexandra> alexandra.dovgal@toughbyte.com"]

    from_addresses = ["\"<Candidate>\" <candidate@gmail.com>"]

    message = Imap::Message.new(
      message_id: "<89cd0353-65ce-e5cd-14c3-1881496eb280@mixmax.com>",
      imap_uid: 10_000,
      in_reply_to: "",
      timestamp: 1_564_402_362,
      flags: ["Seen"],
      to: to_addresses,
      from: from_addresses,
      cc: [],
      bcc: [],
      subject: "Hub2",
      plain_body: "message plain text",
      plain_mime_type: "text/plain",
      html_body: "message html text",
      attachments: [],
      x_failed_recipients: "",
      references: [],
      headers: [],
      autoreply_headers: { auto_submitted: "",
                           x_autoreply: "",
                           x_autorespond: "",
                           precedence: "",
                           x_precedence: "",
                           x_auto_response_suppress: "" }
    )

    message_member =
      EmailSynchronization::MessageMember.new(field: :to, member: members(:employee_member))
    result = @tested_class.new(
      message:,
      email_thread_id: email_threads(:john).id,
      message_member:,
      sent_via: :gmail
    ).call.success

    assert_equal result.fetch_to_addresses.sort,
                 %w[john.founder@toughbyte.com
                    admin@toughbyte.com
                    sergey.tomashevsky@toughbyte.com
                    alexandra.dovgal@toughbyte.com].sort
    assert_equal result.fetch_from_addresses, ["candidate@gmail.com"]
  end
end
