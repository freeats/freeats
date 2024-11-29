# frozen_string_literal: true

require "test_helper"

class EmailTemplateTest < ActiveSupport::TestCase
  test "liquid template validation must work" do
    valid_template = build_stubbed(
      :email_template,
      body: "Hello, {{first_name}}!"
    )
    invalid_template = build_stubbed(
      :email_template,
      body: "{{calendar_url}}"
    )

    assert_predicate valid_template, :valid?
    assert_predicate invalid_template, :invalid?
  end
end
