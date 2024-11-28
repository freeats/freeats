# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/member_note_mailer
class EmailMessageMailerPreview < ActionMailer::Preview
  def send_email
    EmailMessageMailer.with(
      reply_to: Member.all.sample.email_address,
      from: "notifications@freeats.com",
      to: "candidate@email.com",
      cc: "manager@mail.com",
      bcc: "director@mail.com",
      subject: "Email subject",
      html_body: "<p>Email body</p>"
    ).send_email
  end
end
