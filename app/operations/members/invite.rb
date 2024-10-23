# frozen_string_literal: true

class Members::Invite < ApplicationOperation
  include Dry::Monads[:result]

  option :email, Types::Strict::String
  option :actor_account, Types::Instance(Account)

  def call
    access_token = nil
    cleaned_email = email.strip

    return Failure(:invalid_email) unless EmailRegexp::EMAIL_REGEXP.match?(cleaned_email)

    existing_account =
      Account.find_by("LOWER(email) = ?", cleaned_email.downcase)

    return Failure(:account_already_exists) if existing_account

    invite_token = SecureRandom.urlsafe_base64(30)

    existing_tokens =
      AccessToken
      .where(context: :member_invitation)
      .where("LOWER(sent_to) = ?", cleaned_email.downcase)

    AccessToken.transaction do
      existing_tokens.destroy_all
      access_token = AccessToken.create!(
        context: :member_invitation,
        sent_to: cleaned_email,
        sent_at: Time.zone.now,
        hashed_token: Digest::SHA256.digest(invite_token)
      )
    end

    MemberInviteMailer.with(
      invite_token:,
      to: cleaned_email,
      reply_to: actor_account.email,
      company_name: actor_account.tenant.name
    ).invitation.deliver_later

    Success(access_token)
  end
end
