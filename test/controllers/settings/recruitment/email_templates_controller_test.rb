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

    get settings_recruitment_email_template_path(email_templates(:ruby_dev_intro_toughbyte))

    assert_response :success
  end

  test "should open new email template" do
    sign_in accounts(:admin_account)

    get new_settings_recruitment_email_template_path

    assert_response :success
  end

  test "should update existing email template" do
    sign_in accounts(:admin_account)

    email_template = email_templates(:ruby_dev_intro_toughbyte)
    new_subject = "New subject"

    assert_not_equal email_template.subject, new_subject

    patch settings_recruitment_email_template_path(email_template),
          params: { email_template: { subject: "New subject" } }

    email_template.reload

    assert_equal email_template.subject, new_subject

    assert_turbo_stream action: :replace, target: "alerts", status: :success do
      assert_select("template", text: I18n.t("settings.successfully_saved_notice"))
    end
  end

  test "should not update existing email template if we want to set name " \
       "which is already used by another email template" do
    sign_in accounts(:admin_account)

    email_template1 = email_templates(:ruby_dev_intro_toughbyte)
    email_template2 = email_templates(:golang_dev_intro_toughbyte)

    assert_not_equal email_template1.name, email_template2.name

    patch settings_recruitment_email_template_path(email_template1),
          params: { email_template: { name: email_template2.name } }

    assert_turbo_stream action: :replace, target: "alerts", status: :unprocessable_entity do
      assert_select(
        "template",
        text: I18n.t("settings.recruitment.email_templates.name_already_taken_alert")
      )
    end
  end

  test "should create new email template" do
    sign_in accounts(:admin_account)

    assert_difference "EmailTemplate.count" do
      post settings_recruitment_email_templates_path,
           params: { email_template: { name: "New template", message: "New message" } }
    end

    assert_turbo_stream action: :replace, target: "alerts", status: :success do
      assert_select("template", text: I18n.t("settings.successfully_saved_notice"))
    end
  end
end
