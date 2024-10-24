# frozen_string_literal: true

require "test_helper"

class RodauthTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:admin_account)
  end

  test "logs in with a user and a password" do
    post "/sign_in", params: { email: @account.email, password: "password" }

    assert_nil flash[:alert]
    assert_redirected_to "/"
  end

  test "log in with unverified account should return error" do
    email = "myemail@mail.com"
    register(email)

    post "/sign_in", params: { email:, password: "password" }

    assert_equal flash[:alert], I18n.t("rodauth.attempt_to_login_to_unverified_account_error_flash")
    assert_response :forbidden
  end

  test "creates tenant owner with valid data and high recaptcha_v3_score" do
    params = {
      full_name: "My name",
      company_name: "My company",
      email: "myemail@mail.com",
      password: "password",
      "password-confirm": "password",
      recaptcha_v3_score: 0.9
    }

    assert_difference ["Tenant.count", "Account.count", "Member.count"] do
      post "/register", params:
    end

    assert_redirected_to "/verify_email_resend?email=#{CGI.escape(params[:email])}"

    tenant = Tenant.last
    account = Account.last
    member = Member.last
    candidate_source = CandidateSource.last

    assert_equal tenant.name, params[:company_name]
    assert_equal member.access_level, "admin"
    assert_equal member.tenant, tenant
    assert_equal member.account, account
    assert_equal account.tenant, tenant
    assert_equal account.email, params[:email]
    assert_equal account.name, params[:full_name]
    assert_equal candidate_source.tenant, tenant
    assert_equal candidate_source.name, "LinkedIn"
    assert_predicate account.password_hash, :present?
  end

  test "displays recaptcha_v2 modal when recaptcha_v3 score is low and creates an account " \
       "after recaptcha_v2 validation" do
    params = {
      full_name: "My name",
      company_name: "My company",
      email: "myemail@mail.com",
      password: "password",
      "password-confirm": "password",
      recaptcha_v3_score: 0.2
    }

    assert_no_difference ["Tenant.count", "Account.count", "Member.count"] do
      post "/register", params:
    end

    assert_turbo_stream action: :update, target: "turbo_recaptcha"

    params["g-recaptcha-response"] = "valid_recaptcha_v2_token"

    recaptcha_v2_verify_mock = Minitest::Mock.new
    recaptcha_v2_verify_mock.expect(:call, true, [params["g-recaptcha-response"], {}])

    Recaptcha.stub(:verify_via_api_call, recaptcha_v2_verify_mock) do
      assert_difference ["Tenant.count", "Account.count", "Member.count"] do
        post "/register", params:
      end
    end

    assert_redirected_to "/verify_email_resend?email=#{CGI.escape(params[:email])}"

    recaptcha_v2_verify_mock.verify
  end

  test "throws an error with invalid data" do
    params = { full_name: "" }

    assert_no_difference ["Tenant.count", "Account.count", "Member.count"] do
      post "/register", params:
    end
  end

  private

  def register(email)
    params = {
      full_name: "My name",
      company_name: "My company",
      email:,
      password: "password",
      "password-confirm": "password",
      recaptcha_v3_score: 0.9
    }
    post("/register", params:)
  end
end
