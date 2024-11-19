# frozen_string_literal: true

class Notes::Add < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :text, Types::Strict::String
  option :note_thread_params, Types::Strict::Hash.schema(
    id?: Types::Params::Integer,
    candidate_id?: Types::Params::Integer,
    task_id?: Types::Params::Integer
  )
  option :actor_account, Types::Instance(Account)
  option :add_hidden_thread_members, Types::Strict::Bool, default: -> { false }

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

    ActiveRecord::Base.transaction do
      note_thread ||=
        yield NoteThreads::Add.new(
          params: note_thread_params,
          actor_account:
        ).call

      note.note_thread = note_thread
      yield save_note(note)
      add_event(note:, actor_account:)
    end

    send_notifications(note:, actor_account:)

    Success(note)
  end

  private

  def save_note(note)
    note.save!

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:note_invalid, note.errors.full_messages.presence || e.to_s]
  rescue ActiveRecord::RecordNotUnique => e
    Failure[:note_not_unique, note.errors.full_messages.presence || e.to_s]
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

  def add_event(note:, actor_account:)
    Event.create!(
      type: :note_added,
      eventable: note,
      actor_account:
    )
  end

  def send_notifications(note:, actor_account:)
    mentioned_member_emails =
      note
      .not_hidden_mentioned_members
      .includes(:account)
      .map(&:email_address) - [actor_account.email]
    note.send_member_note_notifications(
      mentioned_member_emails,
      current_account: actor_account,
      type: note.task_note? ? "task_mentioned" : "mentioned"
    )

    task_notify_emails, reply_type, created_type =
      if note.task_note?
        [
          note.note_thread.notable.notification_recipients(current_member: actor_account.member),
          "task_replied",
          "task_created"
        ]
      else
        [[], "replied", "created"]
      end

    notified_on_reply_member_emails = []
    if note.note_thread.notes.size > 1
      note_thread_participant_member_emails =
        Member
        .active
        .includes(:account)
        .joins(:notes)
        .where(notes: { note_thread_id: note.note_thread.id })
        .map(&:email_address)
      note_thread_mentioned_member_emails =
        note.note_thread.notes.each_with_object([]) do |nt_note, memo|
          memo.concat(
            nt_note
            .not_hidden_mentioned_members
            .includes(:account)
            .map(&:email_address)
          )
        end
      notified_on_reply_member_emails =
        (note_thread_participant_member_emails + note_thread_mentioned_member_emails +
         task_notify_emails - [actor_account.email] - mentioned_member_emails).uniq

      note.send_member_note_notifications(
        notified_on_reply_member_emails,
        current_account: actor_account,
        type: reply_type
      )
    end

    responsible_for_notable_member =
      case note.note_thread.notable_type
      when "Candidate"
        note.note_thread.notable.recruiter
      when "Task"
        note.note_thread.notable.assignee
      else
        raise ArgumentError, "Note thread must belong to either candidate or task."
      end

    recruiter_and_or_manager_emails =
      if responsible_for_notable_member&.active?
        [responsible_for_notable_member.email_address]
      else
        []
      end
    notify_on_create_emails =
      (recruiter_and_or_manager_emails | task_notify_emails) - mentioned_member_emails -
      notified_on_reply_member_emails - [actor_account.email]

    return if notify_on_create_emails.blank?

    if note.note_thread.hidden?
      # Remove members that the thread is not visible to
      notify_on_create_emails &= note.note_thread.members.includes(:account).map(&:email_address)
    end
    note.send_member_note_notifications(
      notify_on_create_emails,
      current_account: actor_account,
      type: created_type
    )
  end
end
