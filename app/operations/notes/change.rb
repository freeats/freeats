# frozen_string_literal: true

class Notes::Change
  include Dry::Monads[:result, :try]

  include Dry::Initializer.define -> do
    option :id, Types::Strict::String
    option :text, Types::Strict::String
    option :actor_account, Types::Instance(Account)
    option :add_hidden_thread_members, Types::Strict::Bool, default: -> { false }
  end

  def call
    note = Note.find(id)
    note.text = text

    note_thread = note.note_thread

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

    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        note.save!
        note_thread.save!
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
