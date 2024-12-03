# frozen_string_literal: true

require "test_helper"

class EmailMessageSchemaTest < ActiveSupport::TestCase
  include EmailRegexp

  test "EMAIL_ADDRESS_REGEX should work" do
    valid_emails = [
      "smith@gmail.com"
    ]
    invalid_emails = [
      "<smith@gmail.com>",
      "Jake Smith"
    ]

    valid_emails.each do |email|
      assert_match EMAIL_REGEXP, email
    end
    invalid_emails.each do |email|
      assert_no_match EMAIL_REGEXP, email
    end
  end
end
