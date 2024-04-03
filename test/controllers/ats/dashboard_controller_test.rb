# frozen_string_literal: true

require "test_helper"

class ATS::CandidatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in accounts(:admin_account)
  end

  test "should get dashboard" do
    get root_url

    assert_response :success
  end
end
