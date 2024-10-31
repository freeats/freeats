# frozen_string_literal: true

require "test_helper"

class MemberInviteMailerTest < ActionMailer::TestCase
  setup do
    @reply_to = "doreply@example.com"
  end
  test "should send an email with invitation" do
    actor_account = accounts(:admin_account)
    to = "smith.j@gmail.com"
    invite_token = Random.urlsafe_base64(30)

    mail = MemberInviteMailer.with(
      invite_token:,
      to:,
      reply_to: actor_account.email,
      company_name: actor_account.tenant.name
    ).invitation

    assert_equal mail.reply_to, [actor_account.email]
    assert_equal mail.to, [to]
    assert_equal mail.subject, "Invitation to join #{actor_account.tenant.name} on FreeATS"
  end
end
