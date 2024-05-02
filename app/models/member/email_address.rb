# frozen_string_literal: true

class Member::EmailAddress < ApplicationRecord
  has_many :sequences, dependent: :restrict_with_exception
  belongs_to :member

  validates :address, presence: true

  # Gmail accounts are mutated during request, changes should be persisted back to database.
  def self.postprocess_imap_accounts(accounts, update_imap_uid: true)
    unauthorized_accounts = accounts.filter { |acc| acc.status != :succeeded }
    authorized_accounts = accounts - unauthorized_accounts

    where(address: unauthorized_accounts.map(&:email))
      .find_each(&:reset_email_service_tokens)

    return unless update_imap_uid

    authorized_accounts.each do |account|
      find_by!(address: account.email).update!(
        last_email_synchronization_uid: account.last_message_uid
      )
    end
  end

  def imap_account
    Imap::Account.new(
      email: address,
      access_token: token,
      refresh_token:,
      last_email_synchronization_uid:
    )
  end

  def reset_email_service_tokens
    self.token = ""
    self.refresh_token = ""
    save!
  end
end
