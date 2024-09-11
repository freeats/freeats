# frozen_string_literal: true

require "test_helper"

class EmailMessageTest < ActiveSupport::TestCase
  test "should create email_message" do
    EmailMessage.create!(
      email_thread: email_threads(:john),
      message_id: "<CAKmi7MNkBQ_+X606k529-Eqdx4uW0OXyC2bzYE-dA4HKgqdDJA@mail.gmail.com>",
      in_reply_to: "",
      autoreply_headers: {},
      timestamp: Time.zone.now.to_i,
      subject: "Message subject",
      plain_body: "Message body",
      html_body: "<h1>html</h1>",
      plain_mime_type: "text/plain",
      sent_via: :gmail,
      references: [],
      tenant: tenants(:toughbyte_tenant)
    )
  end
end
