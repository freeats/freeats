# frozen_string_literal: true

require "test_helper"

class Settings::Company::GeneralProfilesControllerTest < ActionDispatch::IntegrationTest
  test "should open general company settings" do
    sign_in accounts(:admin_account)

    get settings_company_general_path

    assert_response :success
  end

  test "should update company name if name is valid" do
    sign_in accounts(:admin_account)

    new_valid_name = "New Name"

    patch settings_company_general_path(tenant: { name: new_valid_name })

    assert_response :success

    new_invalid_name = " "

    err = assert_raises(RenderErrorExceptionForTests) do
      patch(settings_company_general_path(tenant: { name: new_invalid_name }))
    end

    err_info = JSON.parse(err.message)

    assert_equal err_info["message"], ["Name can't be blank"]
    assert_equal err_info["status"], "bad_request"
  end
end
