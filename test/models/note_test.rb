# frozen_string_literal: true

require "test_helper"

class NoteTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
  end

  test "should create note, note thread, if it doesn't already exist and event" do
    assert_difference "Event.where(type: 'note_added').count" do
      assert_difference "Note.count" do
        assert_difference "NoteThread.count" do
          Notes::Add.new(
            text: "This is a note",
            note_thread_params: {
              candidate_id: candidates(:sam).id
            },
            actor_account: accounts(:admin_account)
          ).call.value!
        end
      end
    end
  end

  test "should create note if note_thread already exists and event" do
    candidate = candidates(:sam)
    note_thread = NoteThread.create!(
      notable: candidate
    )

    assert_difference "Event.where(type: 'note_added').count" do
      assert_difference "Note.count" do
        assert_no_difference "NoteThread.count" do
          Notes::Add.new(
            text: "This is a note",
            note_thread_params: {
              id: note_thread.id,
              candidate_id: candidate.id
            },
            actor_account: accounts(:admin_account)
          ).call.value!
        end
      end
    end

    assert_equal note_thread.notes.first.text, "This is a note"
  end

  test "should return mentioned_in_hidden_thread failure" do
    mentioned_member = members(:hiring_manager_member)
    candidate = candidates(:sam)
    note_thread = NoteThread.create!(
      notable: candidate,
      hidden: true
    )

    result = nil
    assert_no_difference "Note.count" do
      assert_no_difference "NoteThread.count" do
        result = Notes::Add.new(
          text: "This is a note @#{mentioned_member.account.name}",
          note_thread_params: {
            id: note_thread.id,
            candidate_id: candidate.id
          },
          actor_account: accounts(:admin_account)
        ).call
      end
    end

    assert_equal result, Failure[:mentioned_in_hidden_thread, [mentioned_member.id]]
  end

  test "should update note thread members" do
    actor_account = accounts(:admin_account)
    mentioned_member = members(:hiring_manager_member)
    candidate = candidates(:sam)
    note_thread = NoteThread.create!(
      notable: candidate,
      hidden: true
    )

    assert_difference "Note.count" do
      assert_no_difference "NoteThread.count" do
        Notes::Add.new(
          text: "This is a note @#{mentioned_member.account.name}",
          note_thread_params: {
            id: note_thread.id,
            candidate_id: candidate.id
          },
          add_hidden_thread_members: true,
          actor_account:
        ).call.value!
      end
    end

    assert_equal note_thread.reload.members.sort, [mentioned_member].sort
  end

  test "should destroy note, note_thread if it became empty and create event" do
    note_to_remove = notes(:admin_member_long_note)

    assert_equal note_to_remove.note_thread.notes.count, 1
    assert_difference "Event.where(type: 'note_removed').count" do
      assert_difference "Note.count", -1 do
        assert_difference "NoteThread.count", -1 do
          Notes::Destroy.new(
            id: note_to_remove.id,
            actor_account: accounts(:admin_account)
          ).call.value!
        end
      end
    end
  end

  test "should destroy note, create event and not destroy note_thread if it's not empty" do
    note_to_remove = notes(:admin_member_short_note)

    assert_operator note_to_remove.note_thread.notes.count, :>=, 2
    assert_difference "Event.where(type: 'note_removed').count" do
      assert_difference "Note.count", -1 do
        assert_no_difference "NoteThread.count" do
          Notes::Destroy.new(
            id: note_to_remove.id,
            actor_account: accounts(:admin_account)
          ).call.value!
        end
      end
    end
  end
end
