# frozen_string_literal: true

require "test_helper"

class NoteThreadsControllerTest < ActionDispatch::IntegrationTest
  test "should update note thread" do
    current_account = accounts(:admin_account)
    sign_in current_account

    note_thread = create(:note_thread, notable: candidates(:john), tenant: tenants(:toughbyte_tenant))
    note_thread.members = [members(:hiring_manager_member)]
    create(:note, note_thread:, member: current_account.member, tenant: tenants(:toughbyte_tenant))

    patch note_thread_path(note_thread.id),
          params: { note_thread: { hidden: false, candidate_id: note_thread.notable_id } }

    assert_response :success
    note_thread.reload

    assert_equal note_thread.hidden, false
  end

  test "should update thread's members" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    current_account = accounts(:admin_account)
    sign_in current_account
    note_thread = create(:note_thread, notable: candidates(:john), tenant: tenants(:toughbyte_tenant))
    note_thread.members = [members(:hiring_manager_member)]
    new_members = [members(:employee_member), members(:helen_member)]
    create(:note, note_thread:, member: current_account.member, tenant: tenants(:toughbyte_tenant))

    patch note_thread_path(note_thread.id),
          params: { note_thread: { hidden: true, members: new_members.map(&:id),
                                   candidate_id: note_thread.notable_id } }

    assert_response :success
    note_thread.reload

    assert_equal note_thread.hidden, true
    assert_equal note_thread.members.to_a.sort, [*new_members, current_account.member].sort
  end

  test "should show change_note_thread_visibility_modal" do
    sign_in accounts(:admin_account)

    note_thread = note_threads(:thread_one)
    all_active_members = [members(:interviewer_member)]

    get change_visibility_modal_note_thread_path(note_thread, params: { all_active_members: })

    assert_includes response.body, "Change note thread visibility"
    assert_includes response.body, "Only the selected members will see this thread"
    assert_includes response.body, "Visible to all members"
    assert_includes response.body, "Cancel"
    assert_includes response.body, "Confirm"
  end
end
