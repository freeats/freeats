# frozen_string_literal: true

require "test_helper"

class MemberTest < ActiveSupport::TestCase
  test "should deactivate the member" do
    member = members(:employee_member)
    member.deactivate

    assert_equal member.access_level, "inactive"
  end

  test "should return mentioned members in text" do
    admin_account = accounts(:admin_account)
    employee_account = accounts(:employee_account)
    employee_account.update!(name: "Samuel")
    helen_account = accounts(:helen_account)
    helen_account.update!(name: "Helen The Greatest")

    text = "@#{admin_account.name} @#{employee_account.name} @#{helen_account.name} @nonexistent"

    assert_equal Member.mentioned_in(text).sort,
                 [employee_account.member, admin_account.member, helen_account.member].sort
  end
end
