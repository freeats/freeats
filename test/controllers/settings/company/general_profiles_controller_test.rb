# frozen_string_literal: true

require "test_helper"

class Settings::Company::GeneralProfilesControllerTest < ActionDispatch::IntegrationTest
  test "should open general company settings" do
    skip "TODO: Functionality in the process of implementation."
    sign_in accounts(:interviewer_account)

    get settings_company_general_path

    assert_response :success
  end
end
