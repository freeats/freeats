# frozen_string_literal: true

class Notes::Destroy < ApplicationOperation
  include Dry::Monads[:result, :do, :try]

  option :id, Types::Strict::String | Types::Strict::Integer
  option :actor_account, Types::Instance(Account)

  def call
    note = Note.find(id)
    note_thread = note.note_thread
    notable = note_thread.notable

    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        yield Events::Add.new(
          params:
            {
              type: :note_removed,
              eventable: notable,
              properties: {
                note_id: note.id,
                notable_id: notable.id,
                notable_type: notable.class.name,
                added_actor_account_id: note.added_event.actor_account_id,
                added_at: note.added_event.performed_at
              },
              actor_account:
            }
        ).call

        note.destroy!

        yield NoteThreads::Destroy.new(
          note_thread:
        ).call
      end
    end.to_result

    case result
    in Success(_)
      Success(note_thread)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:note_invalid, note.errors.full_messages.presence || e.to_s]
    end
  end
end
