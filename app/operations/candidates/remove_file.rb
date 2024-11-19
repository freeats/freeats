# frozen_string_literal: true

class Candidates::RemoveFile < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :candidate, Types::Instance(Candidate)
  option :actor_account, Types::Instance(Account)
  option :file, Types::Instance(ActiveStorage::Attachment)

  def call
    ActiveRecord::Base.transaction do
      add_event(candidate:, file:, actor_account:)
      yield remove_file(file)
    end

    Success()
  end

  private

  def remove_file(file)
    file.remove

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:file_invalid, e.to_s]
  end

  def add_event(candidate:, file:, actor_account:)
    properties = {
      name: file.blob.filename,
      active_storage_attachment_id: file.id,
      added_actor_account_id: file.added_event.actor_account_id,
      added_at: file.added_event.performed_at
    }

    Event.create!(
      type: :active_storage_attachment_removed,
      eventable: candidate,
      properties:,
      actor_account:
    )
  end
end
