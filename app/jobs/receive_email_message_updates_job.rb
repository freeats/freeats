# frozen_string_literal: true

class ReceiveEmailMessageUpdatesJob < ApplicationJob
  self.queue_adapter = :solid_queue

  limits_concurrency key: ->(member_id) { member_id }

  queue_as :high

  def perform(member_id)
    imap_accounts = Member::EmailAddress.where(member_id:).map(&:imap_account)

    EmailSynchronization::Synchronize.new(imap_accounts:).call
  end
end
