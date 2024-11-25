# frozen_string_literal: true

class Notes::Destroy < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :id, Types::Strict::String | Types::Strict::Integer
  option :actor_account, Types::Instance(Account)

  def call
    note = Note.find(id)
    note_thread = note.note_thread

    ActiveRecord::Base.transaction do
      add_event(note:, note_thread:, actor_account:)
      yield destroy_note(note, note_thread)
    end

    Success(note_thread)
  end

  private

  def destroy_note(note, note_thread)
    note.destroy!
    yield NoteThreads::Destroy.new(
      note_thread:
    ).call

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:note_invalid, note.errors.full_messages.presence || e.to_s]
  end

  def add_event(note:, note_thread:, actor_account:)
    notable = note_thread.notable
    properties = {
      note_id: note.id,
      notable_id: notable.id,
      notable_type: notable.class.name,
      added_actor_account_id: note.added_event.actor_account_id,
      added_at: note.added_event.performed_at
    }

    Event.create!(
      type: :note_removed,
      eventable: notable,
      properties:,
      actor_account:
    )
  end
end
