# frozen_string_literal: true

require "test_helper"

class MemberTest < ActiveSupport::TestCase
  test "should deactivate the member" do
    member = members(:employee_member)
    member.deactivate

    assert_equal member.access_level, "inactive"
    assert_empty member.account.identities
  end
end
