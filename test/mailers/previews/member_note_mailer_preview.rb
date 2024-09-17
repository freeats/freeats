# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/member_note_mailer
class MemberNoteMailerPreview < ActionMailer::Preview
  def created
    MemberNoteMailer.with(
      current_account: Account.first,
      note: Note.first,
      to:
    ).created
  end

  def mentioned
    MemberNoteMailer.with(
      current_account: Account.first,
      note: Note.second,
      to:
    ).mentioned
  end

  def replied
    MemberNoteMailer.with(
      current_account: Account.first,
      note: Note.third,
      to:
    ).replied
  end

  def task_created
    MemberNoteMailer.with(
      current_account: Account.first,
      note: Note.joins(:note_thread).where(note_threads: { notable_type: "Task" }).first,
      to:
    ).task_created
  end

  def task_mentioned
    MemberNoteMailer.with(
      current_account: Account.first,
      note: Note.joins(:note_thread).where(note_threads: { notable_type: "Task" }).first,
      to:
    ).task_mentioned
  end

  def task_replied
    MemberNoteMailer.with(
      current_account: Account.first,
      note: Note.joins(:note_thread).where(note_threads: { notable_type: "Task" }).first,
      to:
    ).task_replied
  end

  private

  def to
    Member.active.order("random()").first(rand(1..3))
  end
end
