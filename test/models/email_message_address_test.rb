# frozen_string_literal: true

require "test_helper"

class EmailMessageAddressTest < ActiveSupport::TestCase
  test "should create email message address" do
    EmailMessageAddress.create!(
      field: :to,
      address: "john@gmail.com",
      position: 2,
      email_message: email_messages(:john_msg1),
      tenant: tenants(:toughbyte_tenant)
    )
  end
end
