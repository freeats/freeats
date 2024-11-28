# frozen_string_literal: true

require "test_helper"

class EmailSynchronization::RetrieveGmailTokensTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  teardown do
    Faraday.default_connection = nil
  end

  test "should fetch different email and return failure" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("https://oauth2.googleapis.com/token") do |_env|
        [200, { "Content-type" => "application/json; charset=utf-8" },
         EXCHANGE_CODE_FOR_TOKENS_RESPONSE]
      end

      stub.get(
        "https://www.googleapis.com/userinfo/v2/me",
        { "Authorization" => "Bearer #{ACCESS_TOKEN}" }
      ) do |_env|
        [200, { "Content-type" => "application/json; charset=utf-8" },
         FETCH_USERINFO_RESPONSE]
      end
    end
    Faraday.default_connection = Faraday.new { _1.adapter(:test, stubs) }

    redirect_uri =
      Rails.application.routes.url_helpers.link_gmail_settings_personal_profile_url(host: "localhost:3000")
    current_member = members(:employee_member)

    assert_no_difference "Account.where(email: EMAIL_ADDRESS).count" do
      rs = EmailSynchronization::RetrieveGmailTokens.new(
        current_member:,
        code: "secret-gmail-code",
        redirect_uri:
      ).call

      assert_equal rs, Failure[:emails_not_match, EMAIL_ADDRESS]
    end

    assert_not_equal current_member.email_address, EMAIL_ADDRESS
    assert_not_equal current_member.token, ACCESS_TOKEN
    assert_not_equal current_member.refresh_token, REFRESH_TOKEN

    stubs.verify_stubbed_calls
  end

  test "should fetch and set tokens from Gmail for existing record and update it" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("https://oauth2.googleapis.com/token") do |_env|
        [200, { "Content-type" => "application/json; charset=utf-8" },
         EXCHANGE_CODE_FOR_TOKENS_RESPONSE]
      end

      stub.get(
        "https://www.googleapis.com/userinfo/v2/me",
        { "Authorization" => "Bearer #{ACCESS_TOKEN}" }
      ) do |_env|
        [200, { "Content-type" => "application/json; charset=utf-8" },
         FETCH_USERINFO_RESPONSE]
      end
    end
    Faraday.default_connection = Faraday.new { _1.adapter(:test, stubs) }

    redirect_uri =
      Rails.application.routes.url_helpers.link_gmail_settings_personal_profile_url(host: "localhost:3000")
    current_member = members(:employee_member)
    current_member.account.update!(email: EMAIL_ADDRESS)

    assert_empty current_member.token
    assert_empty current_member.refresh_token

    rs = EmailSynchronization::RetrieveGmailTokens.new(
      current_member:,
      code: "secret-gmail-code",
      redirect_uri:
    ).call

    assert_equal rs, Success()

    current_member.reload

    assert_equal current_member.token, ACCESS_TOKEN
    assert_equal current_member.refresh_token, REFRESH_TOKEN

    stubs.verify_stubbed_calls
  end

  ACCESS_TOKEN = "ya29.a0Ad52N39SN2DaO4LxiiwTq2LjDtujHtg_pr05Vdu8jYXLrqzKe6v4BR2dG3LPpkKmoqO8-iT24mNaVWk4vmAwjCQDmVD6323_Kfnbj46v_31VJM8DFvz974NOenitKG-5sQFDrcbY7wh0X9rbgZIA20691k_OW2rn_ZwOaCgYKAaASARMSFQHGX2MimjcXoivYLBa2mMv9E0MEEQ0171" # rubocop:disable Layout/LineLength
  REFRESH_TOKEN = "1//04z4abcdefghijSNwF-L9IrAviFjutCcM_vofXBQmGIeHtGqJHuzqI4v6GkwDLU07W0hmcdGWngRhHDLJaWq5DMHT0"
  EXCHANGE_CODE_FOR_TOKENS_RESPONSE = <<~JSON.freeze
    {
      "access_token": "#{ACCESS_TOKEN}",
      "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjZjZTExYWVjZjllYjE0MDI0YTQ0YmJmZDFiY2Y4YjMyYTEyMjg3ZmEiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiI0MDc0MDg3MTgxOTIuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiI0MDc0MDg3MTgxOTIuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMTM4Mjk0NTMzMDcxOTcxODE4NjMiLCJoZCI6InRvdWdoYnl0ZS5jb20iLCJlbWFpbCI6ImRtaXRyeS5tYXR2ZXlldkB0b3VnaGJ5dGUuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImF0X2hhc2giOiJBdkRpQ05hV1ZDVHFiMUx0eFg1cElnIiwiaWF0IjoxNzEzNDE1ODE2LCJleHAiOjE3MTM0MTk0MTZ9.JKD80XqI4abFFc7ABRQRgepdHTjSESZzSdHqsJBgG67QR1wnXzJsVJxS8uixYUK0jkMok5Kz4fSIgDGnM0Txdn_XBIocPXbGZZi-bAwYHWpE65P9n-FMzMZ3ZHELxgT03TBf5zOCY0Etp8jXWijP6v2kc3usdU43Pg_Kiel1MtBtlSqdIijeOhuQ-05j_1DSqvWsZBafY8gv2v8OKNrVwPYHWXa2hQCYabcHyGjGcCxynHDTz0kzu0RUGdCz5o1L3vKVXbDU1iXAItI-WWmhTaob0o-lZXYbaBr2u-omN4D2hF7YlKiH_3T8KVK5CquGZ3jdIeSTQZXrSnTNIKdiEw",
      "expires_in": 3599,
      "token_type": "Bearer",
      "scope": "https://www.googleapis.com/auth/userinfo.email https://mail.google.com/ openid",
      "refresh_token": "#{REFRESH_TOKEN}"
    }
  JSON
  EMAIL_ADDRESS = "arthur.morgan@example.com"
  FETCH_USERINFO_RESPONSE = <<~JSON.freeze
    {
      "picture": "https://lh3.googleusercontent.com/a-/ALV-UjXMNdDc46rHncbuG5O7aTtirZeLQdd5K1S_CHowXIheWrn4jFU=s96-c",
      "verified_email": true,
      "id": "113829453307197181863",
      "hd": "example.com",
      "email": "#{EMAIL_ADDRESS}"
    }
  JSON
end
