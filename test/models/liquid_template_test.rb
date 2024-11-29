# frozen_string_literal: true

require "test_helper"

class LiquidTemplateTest < ActiveSupport::TestCase
  test "warnings should work" do
    valid_template = LiquidTemplate.new(
      email_templates(:ruby_dev_intro).body.to_s, type: :email_template
    )

    assert_empty valid_template.warnings

    template_with_invalid_syntax = LiquidTemplate.new("Hi, {{%first_name}}", type: :email_template)

    assert_not_empty template_with_invalid_syntax.warnings

    template_with_invalid_variable = LiquidTemplate.new("Hi, {{name}}", type: :email_template)

    assert_not_empty template_with_invalid_variable.warnings
  end

  test "extract_attributes_from method should work" do
    candidate = candidates(:john)
    current_member = members(:employee_member)
    position = positions(:ruby_position)

    result = LiquidTemplate.extract_attributes_from(candidate:, current_member:, position:)

    assert_equal result["full_name"], "John Doe"
    assert_equal result["first_name"], "John"
    assert_equal result["sender_full_name"], "Adrian Barton"
    assert_equal result["sender_first_name"], "Adrian"
    assert_equal result["position"], "Ruby developer"
    assert_equal result["company"], "Toughbyte"
  end

  test "render should work" do
    candidate = candidates(:john)
    current_member = members(:employee_member)
    position = positions(:ruby_position)

    liquid_template = LiquidTemplate.new(email_templates(:ruby_dev_intro).body.to_s)

    render_attributes = LiquidTemplate.extract_attributes_from(candidate:, current_member:, position:)
    rendered = liquid_template.render(render_attributes)

    assert_includes rendered, "Hi, John!"
    assert_includes rendered, "My name is Adrian."
    assert_includes rendered, "I'm looking for Ruby developer"
  end

  test "present_variables method should work" do
    template_only_with_variables =
      LiquidTemplate.new("Hi, {{ first_name }}. I'm looking for {{ position }}.")

    assert_equal template_only_with_variables.present_variables.sort, %w[first_name position]
  end

  test "render should fill missing_variables" do
    template =
      LiquidTemplate.new(
        "Hi, {{ first_name }}! This template is missing {{ sender_first_name }}."
      )

    assert_empty template.missing_variables

    template.render({ "first_name" => "Jake" })

    assert_equal template.missing_variables, %w[sender_first_name]
  end
end
