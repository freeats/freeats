# frozen_string_literal: true

require "test_helper"

class NotesControllerTest < ActionDispatch::IntegrationTest
  test "should not allow member to edit or destroy notes he doesn't own" do
    sign_in accounts(:interviewer_account)
    admin_note = notes(:admin_member_short_note)

    get show_edit_view_note_path(admin_note, render_time: Time.zone.now)

    assert_response :redirect
    assert_redirected_to "/"

    assert_no_difference "Note.count" do
      delete note_path(admin_note)
    end

    assert_response :redirect
    assert_redirected_to "/"

    interviewer_note = notes(:interviewer_reply)

    get show_edit_view_note_path(interviewer_note, render_time: Time.zone.now)

    assert_response :ok

    assert_difference "Event.where(type: 'note_removed').count" do
      assert_difference "Note.count", -1 do
        delete note_path(interviewer_note)
      end
    end

    assert_response :ok
  end

  test "should send email to mentioned members on note creation" do
    current_account = accounts(:admin_account)

    sign_in current_account

    member1 = members(:helen_member)
    member2 = members(:george_member)
    candidate = candidates(:john)
    text = "Hello @#{member1.name} and @#{member2.name}!"

    perform_enqueued_jobs do
      assert_emails 1 do
        post notes_path, params: { note: { text:, note_thread: { candidate_id: candidate.id } } }
      end

      ActionMailer::Base.deliveries.last.tap do |mail|
        assert_equal mail.to.sort, [member1.email_address, member2.email_address].sort
        assert_equal mail.subject, "[#{current_account.name}] commented on #{candidate.full_name}"
      end
    end
  end

  test "should send email to mentioned members on task note creation" do
    current_account = accounts(:admin_account)

    sign_in current_account

    member1 = members(:helen_member)
    member2 = members(:george_member)

    task = tasks(:position)
    watcher = members(:employee_member)

    assert_includes task.watcher_ids, watcher.id

    text = "Hello @#{member1.name} and @#{member2.name}!"

    perform_enqueued_jobs do
      assert_emails 2 do
        post notes_path, params: { note: { text:, note_thread: { task_id: task.id } }, render_time: Time.zone.now }
      end
    end

    notifications = ActionMailer::Base.deliveries.last(2)

    assert(
      notifications.one? do |mail|
        mail.to.sort == [member1.email_address, member2.email_address].sort &&
        mail.subject == "[#{current_account.name}] mentioned you on task on " \
                        "#{task.taskable.name}: #{task.name}"
      end
    )
    assert(
      notifications.one? do |mail|
        mail.to == [watcher.email_address] &&
        mail.subject == "[#{current_account.name}] commented on task on " \
                        "#{task.taskable.name}: #{task.name}"
      end
    )
  end

  test "should send email to task notification recipients on task note reply" do
    current_account = accounts(:admin_account)

    sign_in current_account

    task = tasks(:position)
    task_watcher = members(:employee_member)
    note = notes(:note_task)

    assert_equal note.note_thread.notable_type, "Task"
    assert_equal note.note_thread.notable_id, task.id

    text = "Hello!"

    assert_emails 1 do
      post notes_path,
           params: { note: { text:, note_thread: { id: note.note_thread.id } }, render_time: Time.zone.now }
    end

    ActionMailer::Base.deliveries.last.tap do |mail|
      assert_equal mail.to, [task_watcher.email_address]
      assert_equal mail.subject, "[#{current_account.name}] replied on task on " \
                                 "#{task.taskable.name}: #{task.name}"
    end
  end

  test "should not send reply email to mentioned task notification recipients on task note reply" do
    current_account = accounts(:helen_account)

    sign_in current_account

    task = tasks(:position)
    task_watchers = [members(:employee_member), members(:admin_member)]

    assert_equal task.watchers.sort, task_watchers.sort

    note = notes(:note_task)
    note_member = members(:george_member)
    note.update!(member: note_member)

    assert_equal note.note_thread.notable_type, "Task"
    assert_equal note.note_thread.notable_id, task.id

    text = "Hello @#{task_watchers.first.name} and @#{task_watchers.last.name}!"

    assert_emails 2 do
      post notes_path, params: { note: { text:, note_thread: { id: note.note_thread_id } }, render_time: Time.zone.now }
    end

    notifications = ActionMailer::Base.deliveries.last(2)

    assert(
      notifications.one? do |mail|
        mail.to.sort == task_watchers.map(&:email_address).sort &&
        mail.subject == "[#{current_account.name}] mentioned you on task on " \
                        "#{task.taskable.name}: #{task.name}"
      end
    )
    assert(
      notifications.one? do |mail|
        mail.to == [note_member.email_address] &&
        mail.subject == "[#{current_account.name}] replied on task on " \
                        "#{task.taskable.name}: #{task.name}"
      end
    )
  end

  test "should send emails to thread participants and to mentioned members in all thread notes" \
       "when someone replying to note" do
    current_account = accounts(:admin_account)

    sign_in current_account

    note = notes(:admin_member_long_note)
    candidate = note.note_thread.notable

    first_mentioned_member = members(:helen_member)

    text = "Hello @#{first_mentioned_member.name}!"

    assert_emails 2 do
      post reply_notes_path,
           params: { note: { text:, note_thread: { id: note.note_thread_id } }, render_time: Time.zone.now }
    end

    notifications = ActionMailer::Base.deliveries.last(2)

    assert(
      # Mentioned in the first note member.
      notifications.one? do |mail|
        mail.to == [members(:employee_member).email_address] &&
        mail.subject == "[#{current_account.name}] commented on #{candidate.full_name}"
      end
    )
    assert(
      # Mentioned in the second note member.
      notifications.one? do |mail|
        mail.to == [first_mentioned_member.email_address] &&
        mail.subject == "[#{current_account.name}] commented on #{candidate.full_name}"
      end
    )

    second_mentioned_member = members(:george_member)

    text = "Hello @#{second_mentioned_member.name}!"

    assert_emails 2 do
      post reply_notes_path,
           params: { note: { text:, note_thread: { id: note.note_thread_id } }, render_time: Time.zone.now }
    end

    notifications = ActionMailer::Base.deliveries.last(2)

    assert(
      # Mentioned in the first 2 notes members.
      notifications.one? do |mail|
        mail.to.sort == [members(:employee_member).email_address, first_mentioned_member.email_address].sort &&
        mail.subject == "[#{current_account.name}] commented on #{candidate.full_name}"
      end
    )
    assert(
      # Mentioned in the third note member.
      notifications.one? do |mail|
        mail.to == [second_mentioned_member.email_address] &&
        mail.subject == "[#{current_account.name}] commented on #{candidate.full_name}"
      end
    )
  end

  test "should not send emails if only inactive members participate when someone replying to note" do
    current_account = accounts(:admin_account)

    sign_in current_account

    note = notes(:admin_member_long_note)
    note.update!(text: "note text")
    candidate = note.note_thread.notable
    candidate.update!(recruiter: members(:inactive_member))

    assert_no_emails do
      post reply_notes_path, params: { note: { text: "text", note_thread: { id: note.note_thread_id } } }
    end
  end

  test "should not send recruiter-notify email to candidate's recruiter if he receives " \
       "notify-on-reply email as thread participant" do
    current_account = accounts(:helen_account)

    sign_in current_account

    note = notes(:admin_member_long_note)
    note.update!(text: "note text")
    candidate = note.note_thread.notable
    mentioned_member = members(:admin_member)

    assert_equal candidate.recruiter, mentioned_member

    text = "Hello @#{mentioned_member.name}!"

    assert_emails 1 do
      post reply_notes_path, params: { note: { text:, note_thread: { id: note.note_thread_id } } }
    end
    ActionMailer::Base.deliveries.last.tap do |mail|
      assert_equal mail.to, [mentioned_member.email_address]
      assert_equal mail.subject, "[#{current_account.name}] commented on #{candidate.full_name}"
    end
  end

  test "should not send email to self mentioning members on note creation" do
    current_account = accounts(:admin_account)

    sign_in current_account

    member1 = members(:helen_member)
    member2 = members(:george_member)
    candidate = candidates(:jane)

    assert_emails 1 do
      post notes_path,
           params: {
             note: {
               text: "It should send email to @#{member1.name} and @#{member2.name}, " \
                     "but not to @#{current_account.name}",
               note_thread: {
                 hidden: false,
                 candidate_id: candidate.id
               }
             }
           }
    end

    ActionMailer::Base.deliveries.last.tap do |mail|
      assert_equal mail.to.sort, [member1.email_address, member2.email_address].sort
      assert_equal mail.subject, "[#{current_account.name}] commented on #{candidate.full_name}"
    end
  end

  test "should not send email to non-existant mentioned members on note creation" do
    current_account = accounts(:admin_account)

    sign_in current_account

    mentioned_member = members(:helen_member)
    candidate = candidates(:jane)

    text = "It should send email to @#{mentioned_member.name}, but not to @Fake Name"

    assert_emails 1 do
      post notes_path, params: { note: { text:, note_thread: { candidate_id: candidate.id } } }
    end

    ActionMailer::Base.deliveries.last.tap do |mail|
      assert_equal mail.to, [mentioned_member.email_address]
      assert_equal mail.subject, "[#{current_account.name}] commented on #{candidate.full_name}"
    end
  end

  test "should not send any emails if no members are mentioned on note creation" do
    current_account = accounts(:admin_account)

    sign_in current_account

    text = "No one is mentioned"
    candidate = candidates(:john)

    assert_equal candidate.recruiter, current_account.member

    assert_no_emails do
      post notes_path, params: { note: { text:, note_thread: { candidate_id: candidate.id } } }
    end
  end

  test "should send notification to candidate recruiter on note creation" do
    current_account = accounts(:admin_account)

    sign_in current_account

    recruiter = members(:helen_member)
    candidate = candidates(:john)
    candidate.update!(recruiter:)

    assert_emails 1 do
      post notes_path, params: { note: { text: "text", note_thread: { candidate_id: candidate.id } } }
    end

    ActionMailer::Base.deliveries.last.tap do |mail|
      assert_equal mail.to, [recruiter.email_address]
      assert_equal mail.subject, "[#{current_account.name}] commented on #{candidate.full_name}"
    end
  end

  test "should not send a notification to the recruiter if the member creates a reply to a " \
       "private note thread which invisible to the recruiter" do
    current_account = accounts(:admin_account)

    sign_in current_account

    note = notes(:admin_member_long_note)
    note.update!(text: "note text")

    note_thread = note.note_thread
    note_thread.update!(hidden: true)

    candidate = note_thread.notable
    candidate.update!(recruiter: members(:george_member))

    text = "Recruiter don't see this note"

    assert_emails 0 do
      assert_difference "Note.count" do
        post reply_notes_path, params: { note: { text:, note_thread: { id: note_thread.id } } }
      end
    end
  end

  test "should send notification to mentioned member if private note thread visible to him" do
    current_account = accounts(:admin_account)

    sign_in current_account

    mentioned_member = members(:helen_member)
    note = notes(:admin_member_long_note)
    note.update!(text: "note text")

    note_thread = note.note_thread
    note_thread.update_visibility_settings(
      { hidden: true, members: [mentioned_member] }, current_member: current_account.member
    )

    text = "@#{mentioned_member.account.name} see this note"

    assert_emails 1 do
      post reply_notes_path,
           params: { note: { text:, note_thread: { id: note_thread.id } } }
    end

    ActionMailer::Base.deliveries.last.tap do |mail|
      assert_equal mail.to, [mentioned_member.email_address]
      assert_equal mail.subject, "[#{current_account.name}] commented on #{note_thread.notable.full_name}"
    end
  end

  test "should send notification to recruiter if private note thread visible to him" do
    current_account = accounts(:admin_account)

    sign_in current_account

    recruiter = members(:helen_member)
    note = notes(:admin_member_long_note)
    note.update!(text: "note text")

    candidate = note.note_thread.notable
    candidate.update!(recruiter:)

    note_thread = note.note_thread
    note_thread.update_visibility_settings(
      { hidden: true, members: [recruiter] }, current_member: current_account.member
    )

    text = "Recruiter see this private note"

    assert_emails 1 do
      post reply_notes_path,
           params: { note: { text:, note_thread: { id: note_thread.id } } }
    end

    ActionMailer::Base.deliveries.last.tap do |mail|
      assert_equal mail.to, [recruiter.email_address]
      assert_equal mail.subject, "[#{current_account.name}] commented on #{candidate.full_name}"
    end
  end

  test "should send email only to newly mentioned member on note update" do
    current_account = accounts(:admin_account)

    sign_in current_account

    already_mentioned_member = members(:employee_member)
    new_mentioned_member = members(:helen_member)
    note = notes(:admin_member_long_note)
    candidate = note.note_thread.notable

    assert_includes note.text, already_mentioned_member.name

    assert_emails 1 do
      patch note_path(note),
            params: {
              note: {
                text: "Hello @#{already_mentioned_member.name} and @#{new_mentioned_member.name}!",
                note_thread: { candidate_id: candidate.id }
              }
            }
    end

    ActionMailer::Base.deliveries.last.tap do |mail|
      assert_equal mail.to, [new_mentioned_member.email_address]
      assert_equal mail.subject, "[#{current_account.name}] commented on #{candidate.full_name}"
    end
  end

  test "should add current user's reaction to the note" do
    current_account = accounts(:admin_account)

    sign_in current_account

    note = notes(:admin_member_long_note)

    assert_difference "current_account.member.reacted_notes.count" do
      post add_reaction_note_path(note)
    end
  end

  test "should add current user's reaction to the note with GET request" do
    current_account = accounts(:admin_account)

    sign_in current_account

    note = notes(:admin_member_long_note)

    assert_difference "current_account.member.reacted_notes.count" do
      get add_reaction_note_path(note)
    end
  end

  test "should remove current user's reaction from the note" do
    current_account = accounts(:admin_account)

    sign_in current_account

    note = notes(:admin_member_long_note)

    current_account.member.reacted_notes << note

    assert_difference "current_account.member.reacted_notes.count" => -1 do
      post remove_reaction_note_path(note)
    end
  end
end
