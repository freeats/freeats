# frozen_string_literal: true

require "test_helper"

class MemberNoteMailerTest < ActionMailer::TestCase
  setup do
    @reply_to = "doreply@example.com"
  end
  test "should send an email about the creation of the note" do
    current_account = accounts(:admin_account)
    to = members(:helen_member)
    note = notes(:admin_member_short_note)

    mail = MemberNoteMailer.with(
      current_account:,
      to:,
      note:,
      cc: nil
    ).created

    assert_equal mail.reply_to, [@reply_to]
    assert_equal mail.to, [to.email_address]
    assert_equal mail.subject, "[#{current_account.name}] commented on #{note.note_thread.notable.full_name}"
  end

  test "mentioned should work" do
    current_account = accounts(:admin_account)
    to = members(:george_member)
    note = notes(:admin_member_long_note)
    mail = MemberNoteMailer.with(
      current_account:,
      to:,
      note:
    ).mentioned

    assert_equal mail.reply_to, [@reply_to]
    assert_equal mail.to, [to.email_address]
    assert_equal mail.subject, "[Admin Admin] commented on #{note.note_thread.notable.full_name}"
    assert_includes mail.body.encoded, "Admin Admin"
    assert_includes mail.body.encoded, "mentioned you in a note on #{note.note_thread.notable.full_name}"
  end

  test "replied should work" do
    current_account = accounts(:admin_account)
    to = members(:george_member)
    note = notes(:admin_member_long_note)
    mail = MemberNoteMailer.with(
      current_account:,
      to:,
      note:
    ).replied

    assert_equal mail.reply_to, [@reply_to]
    assert_equal mail.to, [to.email_address]
    assert_equal mail.subject, "[Admin Admin] commented on #{note.note_thread.notable.full_name}"
    assert_includes mail.body.encoded, "Admin Admin"
    assert_includes mail.body.encoded, "replied in a note on #{note.note_thread.notable.full_name}"
  end

  test "task_created should work" do
    current_account = accounts(:admin_account)
    to = members(:helen_member)
    note = notes(:note_task)
    notable = note.note_thread.notable
    mail = MemberNoteMailer.with(
      current_account:,
      to:,
      note:
    ).task_created

    assert_equal mail.reply_to, [@reply_to]
    assert_equal mail.to, [to.email_address]
    assert_equal mail.subject, "[Admin Admin] commented on task on #{notable.taskable_name}: #{notable.name}"
    assert_includes mail.body.encoded, "Admin Admin"
    assert_includes mail.body.encoded, "commented on task on #{notable.taskable_name}"
  end

  test "task_mentioned should work" do
    current_account = accounts(:admin_account)
    to = members(:helen_member)
    note = notes(:note_task)
    notable = note.note_thread.notable
    mail = MemberNoteMailer.with(
      current_account:,
      to:,
      note:
    ).task_mentioned

    assert_equal mail.reply_to, [@reply_to]
    assert_equal mail.to, [to.email_address]
    assert_equal mail.subject, "[Admin Admin] mentioned you on task on #{notable.taskable_name}: #{notable.name}"
    assert_includes mail.body.encoded, "Admin Admin"
    assert_includes mail.body.encoded, "mentioned you on task on #{notable.taskable_name}"
  end

  test "task_replied should work" do
    current_account = accounts(:admin_account)
    to = members(:helen_member)
    note = notes(:note_task)
    notable = note.note_thread.notable
    mail = MemberNoteMailer.with(
      current_account:,
      to:,
      note:
    ).task_replied

    assert_equal mail.reply_to, [@reply_to]
    assert_equal mail.to, [to.email_address]
    assert_equal mail.subject, "[Admin Admin] replied on task on #{notable.taskable_name}: #{notable.name}"
    assert_includes mail.body.encoded, "Admin Admin"
    assert_includes mail.body.encoded, "replied on task on #{notable.taskable_name}"
  end
end
