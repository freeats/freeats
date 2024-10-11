# frozen_string_literal: true

class ReceiveEmailMessageUpdatesJob < ApplicationJob
  self.queue_adapter = :solid_queue

  limits_concurrency key: ->(member_id) { member_id }

  queue_as :high

  def perform(member_id)
    member = Member.find(member_id)
    ActsAsTenant.with_tenant(member.tenant) do
      EmailSynchronization::Synchronize.new(imap_account: member.imap_account).call
    end
  end
end
