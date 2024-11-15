# frozen_string_literal: true

class Candidates::RemoveFile < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :candidate, Types::Instance(Candidate)
  option :actor_account, Types::Instance(Account)
  option :file, Types::Instance(ActiveStorage::Attachment)

  def call
    properties = {
      name: file.blob.filename,
      active_storage_attachment_id: file.id,
      added_actor_account_id: file.added_event.actor_account_id,
      added_at: file.added_event.performed_at
    }
    ActiveRecord::Base.transaction do
      yield add_event(candidate:, properties:, actor_account:)
      file.remove
    end

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:file_invalid, e.to_s]
  end

  private

  def add_event(candidate:, properties:, actor_account:)
    Event.create!(
      type: :active_storage_attachment_removed,
      eventable: candidate,
      properties:,
      performed_at: Time.zone.now,
      actor_account:
    )

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:event_invalid, e.to_s]
  end
end
