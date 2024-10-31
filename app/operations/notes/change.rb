# frozen_string_literal: true

class Notes::Change < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :id, Types::Strict::String
  option :text, Types::Strict::String
  option :actor_account, Types::Instance(Account)
  option :add_hidden_thread_members, Types::Strict::Bool, default: -> { false }

  def call
    note = Note.find(id)

    prev_mentioned_member_emails =
      note.not_hidden_mentioned_members.includes(:account).map(&:email_address)

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

    ActiveRecord::Base.transaction do
      yield save_note(note)
      yield save_note_thread(note_thread)
    end

    send_notifications(note:, actor_account:, prev_mentioned_member_emails:)

    Success(note)
  end

  private

  def save_note(note)
    note.save!

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:note_invalid, note.errors.full_messages.presence || e.to_s]
  end

  def save_note_thread(note_thread)
    note_thread.save!

    Success()
  end

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

  def send_notifications(note:, actor_account:, prev_mentioned_member_emails:)
    type = note.task_note? ? "task_mentioned" : "mentioned"
    emails_to_notify =
      note
      .not_hidden_mentioned_members
      .includes(:account)
      .to_set(&:email_address)
      .subtract(prev_mentioned_member_emails)
      .delete(actor_account.email)
      .to_a

    note.send_member_note_notifications(emails_to_notify, current_account: actor_account, type:)
  end
end
