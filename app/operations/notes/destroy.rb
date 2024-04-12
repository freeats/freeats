# frozen_string_literal: true

class Notes::Destroy
  include Dry::Monads[:result, :do, :try]

  include Dry::Initializer.define -> do
    option :id, Types::Strict::String
    option :actor_account, Types::Instance(Account)
  end

  def call
    note = Note.find(id)

    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        note.destroy!

        yield NoteThreads::Destroy.new(
          note_thread: note.note_thread
        ).call

        # TODO: add events
      end
    end.to_result

    case result
    in Success(_)
      Success(note)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:note_invalid, note.errors.full_messages.presence || e.to_s]
    end
  end
end
