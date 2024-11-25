# frozen_string_literal: true

require "test_helper"

class Settings::Personal::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "should open personal profile settings" do
    sign_in accounts(:interviewer_account)

    get settings_personal_profile_path

    assert_response :success
  end
end
