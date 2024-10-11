# frozen_string_literal: true

class SynchronizeEmailMessagesForEmailJob < ApplicationJob
  self.queue_adapter = :solid_queue

  limits_concurrency key: ->(member_id, addresses) { { member_id => addresses } }

  queue_as :sync_emails

  def perform(member_id, addresses)
    member = Member.find(member_id)
    imap_account = member.imap_account

    ActsAsTenant.with_tenant(member.tenant) do
      unless CandidateEmailAddress
             .joins(:candidate)
             .exists?(candidates: { merged_to: nil }, address: addresses)
        return
      end

      EmailSynchronization::Synchronize.new(
        imap_account:,
        only_for_email_addresses: addresses
      ).call
    end
  end
end
