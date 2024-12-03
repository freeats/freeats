# frozen_string_literal: true

require "test_helper"

class Settings::Company::GeneralProfilesControllerTest < ActionDispatch::IntegrationTest
  test "should open general company settings" do
    sign_in accounts(:admin_account)

    get settings_company_general_path

    assert_response :success
  end

  test "should update company name if name is valid" do
    current_account = accounts(:admin_account)
    sign_in current_account

    new_valid_name = "New Name"

    assert_not_equal current_account.tenant.name, new_valid_name

    patch settings_company_general_path(tenant: { name: new_valid_name })

    assert_response :success
    assert_equal current_account.tenant.reload.name, new_valid_name

    new_invalid_name = " "

    err = assert_raises(RenderErrorExceptionForTests) do
      patch(settings_company_general_path(tenant: { name: new_invalid_name }))
    end

    err_info = JSON.parse(err.message)

    assert_equal err_info["message"], ["Name can't be blank"]
    assert_equal err_info["status"], "bad_request"
    assert_equal current_account.tenant.reload.name, new_valid_name
  end
end
