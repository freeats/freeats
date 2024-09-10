# frozen_string_literal: true

require "test_helper"

class RodauthOauthTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:employee_account)

    setup_oauth_stubs(@account.identities.first.uid, @account.email, "mail.com") =>
      { omniauth_auth:, request_params: }

    @omniauth_auth = omniauth_auth
    @request_params = request_params

    OmniAuth.config.test_mode = true
    OmniAuth.config.logger = Logger.new(nil)
    OmniAuth.config.mock_auth[:google_oauth2] = @omniauth_auth
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.logger = Rails.logger
    OmniAuth.config.test_mode = false
  end

  test "should fail if not requesting Google OAuth" do
    modify_oauth_mock("provider" => "facebook")
    get "/auth/google_oauth2/callback", params: @request_params

    assert_response :not_found
  end

  test "should fail if the account is absent in the system" do
    modify_oauth_mock(
      "info" => { "email" => "absent@mail.com" },
      "uid" => "absent"
    )
    get "/auth/google_oauth2/callback", params: @request_params

    assert_nil flash[:notice]
    assert_equal flash[:alert], "An account with this email does not exist."
    assert_response :redirect
  end

  test "should fail if the account is deactivated when trying to sign in" do
    account = accounts(:inactive_account)
    modify_oauth_mock(
      "info" => { "email" => account.email },
      "uid" => "inactive"
    )
    get "/auth/google_oauth2/callback", params: @request_params

    assert_nil flash[:notice]
    assert_equal flash[:alert], "This account has been deactivated."
    assert_response :redirect
  end

  test "should fail if the account is deactivated when already signed in" do
    account = accounts(:employee_account)
    sign_in account
    account.member.deactivate

    get "/"

    assert_nil flash[:notice]
    assert_equal flash[:alert], "This account has been deactivated."
    assert_response :redirect
  end

  test "should fail if the account has no associated member" do
    account = accounts(:employee_account)
    account.member.destroy!
    modify_oauth_mock(
      "info" => { "email" => account.email },
      "uid" => "inactive"
    )
    get "/auth/google_oauth2/callback", params: @request_params

    assert_nil flash[:notice]
    assert_equal flash[:alert], "This account has no associated member."
    assert_response :redirect
  end

  test "account with existing identity should login without creating any records" do
    assert_no_difference ["Account.count", "Account::Identity.count"] do
      get "/auth/google_oauth2/callback", params: @request_params
    end

    assert_equal flash[:notice], "Signed in successfully, enjoy your session!"
    assert_nil flash[:alert]
    assert_response :redirect
  end

  test "account with no identity should login creating a new identity" do
    account = accounts(:new_employee_account)
    modify_oauth_mock(
      "info" => { "email" => account.email },
      "uid" => "new_employee"
    )
    assert_no_difference "Account.count" do
      assert_difference "Account::Identity.count" do
        get "/auth/google_oauth2/callback", params: @request_params
      end
    end

    assert_equal flash[:notice], "Signed in successfully, enjoy your session!"
    assert_nil flash[:alert]
    assert_response :redirect
  end

  private

  def modify_oauth_mock(hash)
    OmniAuth.config.mock_auth[:google_oauth2] = @omniauth_auth.deep_merge(hash)
  end

  def setup_oauth_stubs(uid, email, domain)
    # This is set in `env["omniauth.auth"]` by the Omniauth gem.
    # rubocop:disable Layout/LineLength
    omniauth_auth = OmniAuth::AuthHash.new(
      "provider" => "google_oauth2",
      "uid" => uid,
      "info" =>
        { "email" => email,
          "unverified_email" => email,
          "email_verified" => true,
          "image" =>
          "https://lh3.googleusercontent.com/a-/ALV-UjVw8mJNbLhkRyH3-JJQOwQMJ8QfNJvyDtU8jWRt-03Q2g=s96-c" },
      "credentials" =>
        { "token" =>
          "ya29.a0Ad52N3-6ks3M-MxzHyokIjFvXoNvc4uNTwmpfOxMZWiaHC9V8BQOnDmYuW0b3F3XZBu3PfOnBmgNYc8rtoMqZjfAe9Xm56VmE6OnwfEfqqbJEjbSKJts0OPu5xr5JdqGS6IyfZ9KOsLfYFjE9jOHsJ4Ya-UboKnh0agaCgYKATESARMSFQHGX2MifpWPhghJU7Uz6rTzAnO8CQ0170",
          "expires_at" => 1_711_439_385,
          "expires" => true,
          "scope" => "https://www.googleapis.com/auth/userinfo.email openid" },
      "extra" =>
        { "id_token" =>
          "eyJhbGciOiJSUzI1NiIsImtpZCI6ImFkZjVlNzEwZWRmZWJlY2JlZmE5YTYxNDk1NjU0ZDAzYzBiOGVkZjgiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiI3OTk1OTg0MTQ3MTUtOTNsajlxNmljaWxubWpqNW1qcTR2dDhnbWUxa2VjdmsuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiI3OTk1OTg0MTQ3MTUtOTNsajlxNmljaWxubWpqNW1qcTR2dDhnbWUxa2VjdmsuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMTM4Mjk0NTMzMDcxOTcxODE4NjMiLCJoZCI6InRvdWdoYnl0ZS5jb20iLCJlbWFpbCI6ImRtaXRyeS5tYXR2ZXlldkB0b3VnaGJ5dGUuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImF0X2hhc2giOiIzODhZczNjdmZvTnJTSnE4M1hmbjNnIiwiaWF0IjoxNzExNDM1Nzg2LCJleHAiOjE3MTE0MzkzODZ9.SEAHIl-eSLTO7tmh_RJDUnFB5d1o2rF73S30iPH01UQgzHYb9l-tqKBdyl63M8ynMYEvr_D9eCpHWpChltMMC8_fHrDAQP07cnyCVw3gO9zcFx-TZB4hi8EaSAYDgO1V9RwAKUfAhtK00k0GCCBfL83vainuEzwZfw4jrTsemPHYFCago_0S8H-rKXwhQtmaIJNpGYSCHVO3FcWaHPibsFm3pBjwFu3DEulQyT37ETZ_pt6nzjG4ZvS6ATpSM_Vu2qDrYfj_EU-yu__aE8Zko3tSzolWBAxql3RRLgJcs6xtQ7nLYnGJNShoEEU6DcSNq83aPxXg29oADdA__MIDVw",
          "id_info" =>
          { "iss" => "https://accounts.google.com",
            "azp" => "799598414715-93lj9q6icilnmjj5mjq4vt8gme1kecvk.apps.googleusercontent.com",
            "aud" => "799598414715-93lj9q6icilnmjj5mjq4vt8gme1kecvk.apps.googleusercontent.com",
            "sub" => "113829453307197181863",
            "hd" => domain,
            "email" => email,
            "email_verified" => true,
            "at_hash" => "388Ys3cvfoNrSJq83Xfn3g",
            "iat" => 1_711_435_786,
            "exp" => 1_711_439_386 },
          "raw_info" =>
          { "sub" => "113829453307197181863",
            "picture" =>
            "https://lh3.googleusercontent.com/a-/ALV-UjVw8mJNbLhkRyH3-JJQOwQMJ8QfNJvyDtU8jWRt-03Q2g=s96-c",
            "email" => email,
            "email_verified" => true,
            "hd" => domain } }
    )
    # rubocop:enable Layout/LineLength

    request_params = {
      "state" => "5df2411b80f6a1bc8168d0b91ec58ce1366e781ef540ec6f",
      "code" => "4/0AeaYSHCTrjWfZYv221ySFjbm5FHySgoRT6j4M61FglyINhS-3I6LfhcE7XxSoKCdXsZyWw",
      "scope" => "email https://www.googleapis.com/auth/userinfo.email openid",
      "authuser" => "0",
      "hd" => domain,
      "prompt" => "none"
    }

    { omniauth_auth:, request_params: }
  end
end
