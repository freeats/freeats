# frozen_string_literal: true

class Notes::Add
  include Dry::Monads[:result, :do, :try]

  include Dry::Initializer.define -> do
    option :text, Types::Strict::String
    option :note_thread_params, Types::Strict::Hash.schema(
      id?: Types::Params::Integer,
      candidate_id?: Types::Params::Integer,
      task_id?: Types::Params::Integer
    )
    option :actor_account, Types::Instance(Account)
    option :add_hidden_thread_members, Types::Strict::Bool, default: -> { false }
  end

  def call
    note_thread =
      (NoteThread.find_by(id: note_thread_params[:id]) if note_thread_params.key?(:id))

    if note_thread.present?
      forbidden_member_ids = mentioned_in_hidden_thread_members(
        note_thread:,
        text:,
        current_member_id: actor_account.member.id
      )
      if !add_hidden_thread_members && forbidden_member_ids.present?
        return Failure[:mentioned_in_hidden_thread, forbidden_member_ids]
      elsif add_hidden_thread_members
        note_thread.members = Member.where(id: [*note_thread.members.ids, *forbidden_member_ids])
      end
    end

    note = Note.new(text:, member: actor_account.member)

    result = Try[ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique] do
      ActiveRecord::Base.transaction do
        note_thread ||=
          yield NoteThreads::Add.new(
            params: note_thread_params,
            actor_account:
          ).call

        note.note_thread = note_thread
        note.save!

        yield Events::Add.new(
          params:
            {
              type: :note_added,
              eventable: note,
              actor_account:
            }
        ).call
        note
      end
    end.to_result

    case result
    in Success(note)
      Success(note)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:note_invalid, note.errors.full_messages.presence || e.to_s]
    in Failure[ActiveRecord::RecordNotUnique => e]
      Failure[:note_not_unique, note.errors.full_messages.presence || e.to_s]
    end
  end

  private

  def mentioned_in_hidden_thread_members(note_thread:, text:, current_member_id:)
    thread_is_hidden = note_thread.hidden
    allowed_member_ids = note_thread.members.ids
    forbidden_member_ids =
      Note.mentioned_members_ids(text) - [*allowed_member_ids, current_member_id]

    if thread_is_hidden && forbidden_member_ids.present?
      forbidden_member_ids
    else
      []
    end
  end
end
