# frozen_string_literal: true

require "test_helper"

class Member::EmailAddressTest < ActiveSupport::TestCase
  test "should create a member email address" do
    member = members(:employee_member)

    Member::EmailAddress.create!(
      member:,
      address: "test@email.com",
      token: "token",
      refresh_token: "refresh_token",
      last_email_synchronization_uid: Time.zone.now.to_s
    )
  end

  test "should create a member email address with default values" do
    member = members(:employee_member)
    Member::EmailAddress.create!(member:, address: "test@email.com")
  end
end
