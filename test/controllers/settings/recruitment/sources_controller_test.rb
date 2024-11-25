# frozen_string_literal: true

require "test_helper"

class Settings::Recruitment::SourcesControllerTest < ActionDispatch::IntegrationTest
  test "should open sources recruitment settings" do
    sign_in accounts(:interviewer_account)

    get settings_recruitment_source_path

    assert_response :success
  end
end
