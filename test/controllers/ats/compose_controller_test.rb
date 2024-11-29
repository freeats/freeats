# frozen_string_literal: true

require "test_helper"

class ATS::ComposeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_account = accounts(:employee_account)
    sign_in @current_account
  end

  test "should get new compose form" do
    get new_ats_compose_path(params: { candidate_id: candidates(:jake).id })

    assert_response :success
  end

  test "should send new email" do
    params = {
      email_message: {
        subject: "Test email",
        html_body: "<p>Email test body</p>",
        to: ["jake@smith.com"],
        cc: ["recruiter@mail.com"],
        bcc: ["manager@mail.com"]
      }
    }

    assert_emails 1 do
      post ats_compose_index_path(params:)
    end

    assert_turbo_stream action: :replace, target: "alerts", status: :success do
      assert_select(
        "template",
        text: I18n.t("candidates.email_compose.email_sent_success_notice",
                     email_addresses: params[:email_message][:to].join(", "))
      )
    end

    ActionMailer::Base.deliveries.last.tap do |mail|
      assert_equal mail.to, params[:email_message][:to]
      assert_equal mail.cc, params[:email_message][:cc]
      assert_equal mail.bcc, params[:email_message][:bcc]
      assert_equal mail.subject, params[:email_message][:subject]
      assert_includes mail.body.raw_source, params[:email_message][:html_body]

      assert_equal mail.from, [ATS::ComposeController::FROM_ADDRESS]
      assert_equal mail.reply_to, [@current_account.email]
    end
  end

  test "should display validation error" do
    params = {
      email_message: {
        subject: "Test email",
        html_body: "<p>Email test body</p>",
        to: ["Jake Smith"]
      }
    }

    exception = nil
    assert_no_emails do
      exception = assert_raise(RenderErrorExceptionForTests) do
        post(ats_compose_index_path(params:))
      end
    end

    assert_includes exception.message, "to, 0: is in invalid format"
  end

  test "should display alert when email was not sent" do
    params = {
      email_message: {
        subject: "Test email",
        html_body: "<p>Email test body</p>",
        to: ["jake@smith.com"]
      }
    }

    email_message_params =
      params[:email_message].merge(
        from: ATS::ComposeController::FROM_ADDRESS,
        reply_to: @current_account.email,
        cc: [],
        bcc: []
      )

    mailer_mock = Minitest::Mock.new
    mailer_mock.expect :call, mailer_mock, [email_message_params]
    mailer_mock.expect :send_email, mailer_mock
    mailer_mock.expect :deliver_now!, nil

    external_log_mock = Minitest::Mock.new
    external_log_mock.expect(
      :call,
      true,
      ["email message was not sent"],
      email_message_params:,
      result: "nil"
    )

    Log.stub :external_log, external_log_mock do
      assert_no_emails do
        EmailMessageMailer.stub :with, mailer_mock do
          post(ats_compose_index_path(params:))
        end
      end
    end

    mailer_mock.verify
    external_log_mock.verify

    assert_turbo_stream action: :replace, target: "alerts", status: :unprocessable_entity do
      assert_select(
        "template",
        text: I18n.t("candidates.email_compose.email_sent_fail_alert",
                     email_addresses: params[:email_message][:to].join(", "))
      )
    end
  end
end
