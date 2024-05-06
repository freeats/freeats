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
end
