# frozen_string_literal: true

require "test_helper"

class Settings::Recruitment::SourcesControllerTest < ActionDispatch::IntegrationTest
  test "should open sources recruitment settings" do
    skip "TODO: Functionality in the process of implementation."
    sign_in accounts(:interviewer_account)

    get settings_recruitment_sources_path

    assert_response :success
  end
end
