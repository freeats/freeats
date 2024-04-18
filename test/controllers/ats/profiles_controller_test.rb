# frozen_string_literal: true

require "test_helper"

class ATS::ProfilesControllerTest < ActionDispatch::IntegrationTest
  include Dry::Monads[:result]

  test "should get show" do
    sign_in accounts(:employee_account)
    get ats_profile_url

    assert_response :success
  end

  test "should link Gmail" do
    sign_in accounts(:employee_account)
    retrieve_gmail_tokens_mock = Minitest::Mock.new
    retrieve_gmail_tokens_mock.expect(:call, Success(), [])

    EmailSynchronization::RetrieveGmailTokens.stub(:new, ->(*) { retrieve_gmail_tokens_mock }) do
      get link_gmail_ats_profile_url, params: { code: "OAuthcode" }
    end

    assert_response :redirect
    assert_equal flash[:notice], "Gmail successfully linked."
    retrieve_gmail_tokens_mock.verify
  end

  test "should report error if something goes wrong when linking Gmail" do
    sign_in accounts(:employee_account)
    exc = RuntimeError.new
    exc.set_backtrace([])
    retrieve_gmail_tokens_mock = Minitest::Mock.new
    retrieve_gmail_tokens_mock.expect(:call, Failure[:failed_to_fetch_tokens, exc], [])
    retrieve_gmail_tokens_mock.expect(:call, Failure[:failed_to_retrieve_email_address, exc], [])
    retrieve_gmail_tokens_mock.expect(:call, Failure[:invalid_member_email_address, exc], [])

    EmailSynchronization::RetrieveGmailTokens.stub(:new, ->(*) { retrieve_gmail_tokens_mock }) do
      3.times do
        get link_gmail_ats_profile_url, params: { code: "OAuthcode" }

        assert_response :redirect
        assert_not_empty flash[:alert]
      end
    end

    retrieve_gmail_tokens_mock.verify
  end
end
