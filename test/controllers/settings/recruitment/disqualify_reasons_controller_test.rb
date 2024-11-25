# frozen_string_literal: true

require "test_helper"

class Settings::Recruitment::DisqualifyReasonsControllerTest < ActionDispatch::IntegrationTest
  test "should open disqualify reasons recruitment settings" do
    sign_in accounts(:interviewer_account)

    get settings_recruitment_disqualify_reasons_path

    assert_response :success
  end
end
