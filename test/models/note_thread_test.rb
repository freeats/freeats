# frozen_string_literal: true

require "test_helper"

class NoteThreadTest < ActiveSupport::TestCase
  test "should create note thread" do
    candidate = candidates(:john)
    note_thread =
      NoteThread.create!(
        notable: candidate,
        tenant: tenants(:toughbyte_tenant)
      )

    assert_equal note_thread.notable, candidate
  end
end
