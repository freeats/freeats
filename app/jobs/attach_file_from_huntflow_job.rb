# frozen_string_literal: true

class AttachFileFromHuntflowJob < ApplicationJob
  def perform(candidate_id:, info_hash:, huntflow_actor_account_id:, file_added_at:)
    candidate = Candidate.find_by(id: candidate_id)

    return unless candidate

    actor_account = Account.find_by(external_source_id: huntflow_actor_account_id)

    return unless actor_account

    file_io = URI.parse(info_hash[:url]).open

    ActiveRecord::Base.transaction do
      attachment =
        candidate
        .files
        .attach(io: file_io, filename: info_hash[:name])
        .attachments
        .last

      Event.create!(
        type: :active_storage_attachment_added,
        eventable: attachment,
        actor_account:,
        performed_at: file_added_at,
        properties: { name: info_hash[:name] }
      )
    end
  end
end
