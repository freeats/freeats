# frozen_string_literal: true

class Member::EmailAddress < ApplicationRecord
  belongs_to :member

  validates :address, presence: true

  def imap_account
    Imap::Account.new(
      email: address,
      access_token: token,
      refresh_token:,
      last_email_synchronization_uid:
    )
  end
end
