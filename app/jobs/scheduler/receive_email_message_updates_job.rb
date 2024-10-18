# frozen_string_literal: true

class Scheduler::ReceiveEmailMessageUpdatesJob < ApplicationJob
  self.queue_adapter = :solid_queue

  limits_concurrency key: "receive_email_message_updates"

  queue_as :scheduler

  def perform
    Member.with_linked_email_service.pluck(:id).each do |member_id|
      ReceiveEmailMessageUpdatesForMemberJob.perform_later(member_id)
    end
  end
end
