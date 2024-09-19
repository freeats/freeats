# frozen_string_literal: true

require "test_helper"

class RodauthTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:admin_ru_account)
  end

  test "logs in with a user and a password" do
    skip "TODO"

    tenant = tenants(:toughbyte_tenant)
    newly_registered = Account.create!(name: "a", email: "a@a.ru", password: "password", tenant:)
    Member.create!(tenant:, account: newly_registered, access_level: :admin)
    post "/sign_in", params: { email: newly_registered.email, password: "password" }

    assert_redirected_to "/"
  end

  test "creates tenant owner with valid data" do
    params = {
      full_name: "My name",
      company_name: "My company",
      email: "myemail@mail.com",
      password: "password",
      "password-confirm": "password"
    }

    assert_difference ["Tenant.count", "Account.count", "Member.count"] do
      post "/register", params:
    end

    assert_redirected_to "/"

    tenant = Tenant.last
    account = Account.last
    member = Member.last

    assert_equal tenant.name, params[:company_name]
    assert_equal member.access_level, "admin"
    assert_equal member.tenant, tenant
    assert_equal member.account, account
    assert_equal account.tenant, tenant
    assert_equal account.email, params[:email]
    assert_equal account.name, params[:full_name]
    assert_predicate account.password_hash, :present?
  end

  test "throws an error with invalid data" do
    params = { full_name: "" }

    assert_no_difference ["Tenant.count", "Account.count", "Member.count"] do
      post "/register", params:
    end
  end
end
