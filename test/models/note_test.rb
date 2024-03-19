# frozen_string_literal: true

require "test_helper"

class NoteTest < ActiveSupport::TestCase
  test "should not create note without note thread" do
    assert_raises(ActiveRecord::RecordInvalid) do
      Note.create!(text: "This is a note")
    end
  end

  test "should create note" do
    note = Note.create!(text: "This is a note", note_thread: note_threads(:thread_one))

    assert_equal note.text, "This is a note"
  end
end
