# frozen_string_literal: true

require "test_helper"

class RodauthsControllerTest < ActionDispatch::IntegrationTest
  test "should display the invitation page" do
    token = SecureRandom.urlsafe_base64(30)
    AccessToken.create!(
      sent_at: Time.zone.now,
      hashed_token: Digest::SHA256.digest(token),
      sent_to: "member_invite@mail.com",
      context: "member_invitation",
      tenant: tenants(:toughbyte_tenant)
    )

    get invitation_path(token:)

    assert_response :success
  end

  test "should render a 404 page if no invitation token is provided" do
    get invitation_path

    assert_response :not_found

    post accept_invite_path

    assert_response :not_found
  end

  test "should redirect to the dashboard if an account is already logged in and destroy access tokens" do
    sign_in accounts(:admin_account)

    expired_token = SecureRandom.urlsafe_base64(30)
    expired_access_token = AccessToken.create!(
      sent_at: 2.years.ago,
      hashed_token: Digest::SHA256.digest(expired_token),
      sent_to: "member_invite@mail.com",
      context: "member_invitation",
      tenant: tenants(:toughbyte_tenant)
    )
    not_expired_token = SecureRandom.urlsafe_base64(30)
    not_expired_access_token = AccessToken.create!(
      sent_at: Time.zone.now,
      hashed_token: Digest::SHA256.digest(not_expired_token),
      sent_to: "member_invite@mail.com",
      context: "member_invitation",
      tenant: tenants(:toughbyte_tenant)
    )

    get invitation_path(token: expired_token)

    assert_redirected_to root_path
    assert_equal flash[:warning], "You already have an account."
    assert_empty AccessToken.where(id: [expired_access_token.id, not_expired_access_token.id])
  end

  test "should redirect to the dashboard if an account is already logged and the access token does not exist" do
    sign_in accounts(:admin_account)

    assert_no_difference "AccessToken.count" do
      get invitation_path(token: 12_345)
    end

    assert_redirected_to root_path
    assert_equal flash[:warning], "You already have an account."
  end

  test "should redirect to the sign in page if no access token is found" do
    get invitation_path(token: 12_345)

    assert_redirected_to "/sign_in"
    assert_equal flash[:alert], "There's no pending invitation, please ask to re-send the invitation."
  end

  test "should redirect to the sign in page if the sent_to email is already used in an existing account " \
       "and destroy access tokens" do
    expired_token = SecureRandom.urlsafe_base64(30)
    expired_access_token = AccessToken.create!(
      sent_at: 2.years.ago,
      hashed_token: Digest::SHA256.digest(expired_token),
      sent_to: accounts(:admin_account).email,
      context: "member_invitation",
      tenant: tenants(:toughbyte_tenant)
    )
    not_expired_token = SecureRandom.urlsafe_base64(30)
    not_expired_access_token = AccessToken.create!(
      sent_at: Time.zone.now,
      hashed_token: Digest::SHA256.digest(not_expired_token),
      sent_to: accounts(:admin_account).email,
      context: "member_invitation",
      tenant: tenants(:toughbyte_tenant)
    )

    get invitation_path(token: not_expired_token)

    assert_redirected_to "/sign_in"
    assert_equal flash[:warning], "You have already registered, please sign in."
    assert_empty AccessToken.where(id: [expired_access_token.id, not_expired_access_token.id])
  end

  test "should redirect to the sign in page if the invitation token is expired" do
    token = SecureRandom.urlsafe_base64(30)
    AccessToken.create!(
      sent_at: 2.years.ago,
      hashed_token: Digest::SHA256.digest(token),
      sent_to: "member_invite@mail.com",
      context: "member_invitation",
      tenant: tenants(:toughbyte_tenant)
    )

    get invitation_path(token:)

    assert_redirected_to "/sign_in"
    assert_equal flash[:alert], "Your invitation has expired, please ask to re-send the invitation."
  end

  test "should not create member via invite token if passwords do not match" do
    token = SecureRandom.urlsafe_base64(30)
    AccessToken.create!(
      sent_at: Time.zone.now,
      hashed_token: Digest::SHA256.digest(token),
      sent_to: "member_invite@mail.com",
      context: "member_invitation",
      tenant: tenants(:toughbyte_tenant)
    )

    assert_no_difference ["Account.count", "Member.count", "Tenant.count"] do
      post accept_invite_path,
           params: { token:, full_name: "John Doe", password: "password", "password-confirm" => "password1" }
    end

    assert_response :unprocessable_entity
    assert_equal flash[:alert], "There was an error creating your account."

    failed_input = css_select("#password").first

    assert_includes failed_input["class"], "is-invalid"
  end

  test "should not create a member via invite token if no full_name is present" do
    token = SecureRandom.urlsafe_base64(30)
    AccessToken.create!(
      sent_at: Time.zone.now,
      hashed_token: Digest::SHA256.digest(token),
      sent_to: "member_invite@mail.com",
      context: "member_invitation",
      tenant: tenants(:toughbyte_tenant)
    )

    assert_no_difference ["Account.count", "Member.count", "Tenant.count"] do
      post accept_invite_path,
           params: { token:, password: "password", "password-confirm" => "password" }
    end

    assert_response :unprocessable_entity
    assert_equal flash[:alert], "There was an error creating your account."

    failed_input = css_select("#full_name").first

    assert_includes failed_input["class"], "is-invalid"
  end

  test "should create a member via not expired invite token, auto login him and redirect to root_path " \
       "and destroy access tokens" do
    sent_to = "member_invite@mail.com"
    expired_token = SecureRandom.urlsafe_base64(30)
    expired_access_token = AccessToken.create!(
      sent_at: 2.years.ago,
      hashed_token: Digest::SHA256.digest(expired_token),
      sent_to:,
      context: "member_invitation",
      tenant: tenants(:toughbyte_tenant)
    )
    not_expired_token = SecureRandom.urlsafe_base64(30)
    not_expired_access_token = AccessToken.create!(
      sent_at: Time.zone.now,
      hashed_token: Digest::SHA256.digest(not_expired_token),
      sent_to:,
      context: "member_invitation",
      tenant: tenants(:toughbyte_tenant)
    )

    assert_difference ["Account.count", "Member.count"] do
      assert_no_difference "Tenant.count" do
        assert_no_emails do
          post accept_invite_path,
               params: { token: not_expired_token, full_name: "John Wick", password: "password",
                         "password-confirm" => "password" }
        end
      end
    end

    assert_redirected_to root_path
    assert_equal flash[:notice], "Welcome! You have signed up successfully."

    account = Account.last

    assert_equal account.status, "verified"
    assert_equal account.email, sent_to
    assert_equal Member.last.access_level, "member"
    assert_empty AccessToken.where(id: [expired_access_token.id, not_expired_access_token.id])
  end

  test "should not create a member via expired invite token " \
       "when there exists the not expired invite token sent to the same address " \
       "and do not destroy access tokens" do
    sent_to = "member_invite@mail.com"
    expired_token = SecureRandom.urlsafe_base64(30)
    AccessToken.create!(
      sent_at: 2.years.ago,
      hashed_token: Digest::SHA256.digest(expired_token),
      sent_to:,
      context: "member_invitation",
      tenant: tenants(:toughbyte_tenant)
    )
    not_expired_token = SecureRandom.urlsafe_base64(30)
    AccessToken.create!(
      sent_at: Time.zone.now,
      hashed_token: Digest::SHA256.digest(not_expired_token),
      sent_to:,
      context: "member_invitation",
      tenant: tenants(:toughbyte_tenant)
    )

    assert_no_difference ["Account.count", "Member.count", "Tenant.count", "AccessToken.count"] do
      post accept_invite_path,
           params: { token: expired_token, full_name: "John Wick", password: "password",
                     "password-confirm" => "password" }
    end

    assert_redirected_to "/sign_in"
    assert_equal flash[:alert], "Your invitation has expired, please ask to re-send the invitation."
  end
end
