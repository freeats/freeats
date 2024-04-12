# frozen_string_literal: true

class NoteThreads::Destroy
  include Dry::Monads[:result, :try]

  include Dry::Initializer.define -> do
    option :note_thread, Types::Instance(NoteThread)
  end

  def call
    result = Try[ActiveRecord::RecordInvalid] do
      note_thread.destroy! if note_thread.notes.blank?
    end.to_result

    case result
    in Success(_)
      Success(note_thread)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:note_thread_invalid, note_thread.errors.full_messages.presence || e.to_s]
    end
  end
end
