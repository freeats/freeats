# frozen_string_literal: true

require "test_helper"

class Settings::Recruitment::EmailTemplatesControllerTest < ActionDispatch::IntegrationTest
  test "should open email templates recruitment settings for admin" do
    sign_in accounts(:admin_account)

    get settings_recruitment_email_templates_path

    assert_response :success
  end

  test "should not open email templates recruitment settings for member" do
    sign_in accounts(:employee_account)

    get settings_recruitment_email_templates_path

    assert_response :redirect
  end

  test "should open existing email template" do
    sign_in accounts(:admin_account)

    get settings_recruitment_email_template_path(email_templates(:ruby_dev_intro))

    assert_response :success
  end

  test "should open new email template" do
    sign_in accounts(:admin_account)

    get new_settings_recruitment_email_template_path

    assert_response :success
  end
end
