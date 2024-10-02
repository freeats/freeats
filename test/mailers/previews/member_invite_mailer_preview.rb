# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/
class MemberInviteMailerPreview < ActionMailer::Preview
  def invitation
    invite_token = Random.urlsafe_base64(30)
    to = Faker::Internet.email
    actor_account = Account.all.sample
    AccessToken.create!(
      tenant: Tenant.all.sample,
      context: :member_invitation,
      sent_to: to,
      sent_at: Time.zone.now,
      hashed_token: Digest::SHA256.digest(invite_token)
    )
    MemberInviteMailer.with(
      invite_token:,
      to:,
      reply_to: actor_account.email,
      company_name: actor_account.tenant.name
    ).invitation
  end
end
