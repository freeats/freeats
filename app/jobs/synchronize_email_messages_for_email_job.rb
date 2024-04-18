# frozen_string_literal: true

class SynchronizeEmailMessagesForEmailJob < ApplicationJob
  self.queue_adapter = :solid_queue

  queue_as :sync_emails

  def perform(address)
    unless CandidateEmailAddress.joins(:candidate).exists?(candidates: { merged_to: nil }, address:)
      return
    end

    EmailSynchronization::Synchronize.new(
      imap_accounts: Member.imap_accounts,
      only_for_email_addresses: [address]
    ).call
  end
end
