# frozen_string_literal: true

namespace :scheduler do
  desc "Runs every 10 minutes"
  task receive_email_message_updates: :environment do
    next if ENV["PAUSE_SCHEDULER"] == "true"

    Member.with_linked_email_service.pluck(:id).each do |member_id|
      ReceiveEmailMessageUpdatesJob.perform_later(member_id)
    end
  end
end
