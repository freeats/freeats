# frozen_string_literal: true

require "test_helper"

class MemberEmailAddressTest < ActiveSupport::TestCase
  test "should create a member email address" do
    member = members(:employee_member)

    member_email_address =
      MemberEmailAddress.create!(
        member:,
        address: "test@email.com",
        token: "token",
        refresh_token: "refresh_token",
        last_email_synchronization_uid: Time.zone.now.to_s
      )

    assert member_email_address.id
  end
end
