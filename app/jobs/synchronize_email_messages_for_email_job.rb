# frozen_string_literal: true

class SynchronizeEmailMessagesForEmailJob < ApplicationJob
  self.queue_adapter = :solid_queue

  limits_concurrency key: ->(member_id, addresses) { { member_id => addresses } }

  queue_as :sync_emails

  def perform(member_id, addresses)
    unless CandidateEmailAddress
           .joins(:candidate)
           .exists?(candidates: { merged_to: nil }, address: addresses)
      return
    end

    imap_accounts = Member::EmailAddress.where(member_id:).map(&:imap_account)

    EmailSynchronization::Synchronize.new(
      imap_accounts:,
      only_for_email_addresses: addresses
    ).call
  end
end
