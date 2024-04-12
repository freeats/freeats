# frozen_string_literal: true

require "test_helper"

class NoteTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  test "should create note and note thread" do
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

  test "should create note" do
    candidate = candidates(:sam)
    note_thread = NoteThread.create!(
      notable: candidate
    )

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
end
