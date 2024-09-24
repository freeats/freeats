# frozen_string_literal: true

require "test_helper"

class ATS::SettingsControllerTest < ActionDispatch::IntegrationTest
  include Dry::Monads[:result]

  test "should get show" do
    sign_in accounts(:employee_account)
    get ats_settings_url

    assert_response :success
  end

  test "should link Gmail" do
    skip "This functionality is currently hidden."

    sign_in accounts(:employee_account)
    retrieve_gmail_tokens_mock = Minitest::Mock.new
    retrieve_gmail_tokens_mock.expect(:call, Success(), [])

    EmailSynchronization::RetrieveGmailTokens.stub(:new, ->(*) { retrieve_gmail_tokens_mock }) do
      get link_gmail_ats_settings_url, params: { code: "OAuthcode" }
    end

    assert_response :redirect
    assert_equal flash[:notice], "Gmail successfully linked."
    retrieve_gmail_tokens_mock.verify
  end

  test "should report error if something goes wrong when linking Gmail" do
    skip "This functionality is currently hidden."

    sign_in accounts(:employee_account)
    exc = RuntimeError.new
    exc.set_backtrace([])
    new_email = "random@email.com"
    retrieve_gmail_tokens_mock = Minitest::Mock.new
    retrieve_gmail_tokens_mock.expect(:call, Failure[:failed_to_fetch_tokens, exc], [])
    retrieve_gmail_tokens_mock.expect(:call, Failure[:failed_to_retrieve_email_address, exc], [])
    retrieve_gmail_tokens_mock.expect(:call, Failure[:emails_not_match, new_email], [])
    retrieve_gmail_tokens_mock.expect(:call, Failure[:new_tokens_are_not_saved, exc], [])

    flash_messages = [
      "Something went wrong, please contact support.",
      "Something went wrong, please contact support.",
      "The linked email #{new_email} does not match the current email.",
      "Something went wrong, please contact support."
    ]

    EmailSynchronization::RetrieveGmailTokens.stub(:new, ->(*) { retrieve_gmail_tokens_mock }) do
      4.times do |i|
        get link_gmail_ats_settings_url, params: { code: "OAuthcode" }

        assert_response :redirect
        assert_not_empty flash[:alert]
        assert_equal flash[:alert], flash_messages[i]
      end
    end

    retrieve_gmail_tokens_mock.verify
  end
end
