# frozen_string_literal: true

require "test_helper"

class EmailMessageMailerTest < ActionMailer::TestCase
  test "should send an email" do
    email_message_params = {
      reply_to: Member.all.sample.email_address,
      from: "notifications@freeats.com",
      to: "candidate@email.com",
      cc: "manager@mail.com",
      bcc: "director@mail.com",
      subject: "Email subject",
      html_body: "<p>Email body</p>"
    }

    mail = EmailMessageMailer.with(email_message_params).send_email

    assert_equal mail.reply_to, [email_message_params[:reply_to]]
    assert_equal mail.from, [email_message_params[:from]]
    assert_equal mail.to, [email_message_params[:to]]
    assert_equal mail.cc, [email_message_params[:cc]]
    assert_equal mail.bcc, [email_message_params[:bcc]]
    assert_equal mail.subject, email_message_params[:subject]
    assert_includes mail.body.raw_source, email_message_params[:html_body]
  end
end
