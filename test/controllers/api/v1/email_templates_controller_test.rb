# frozen_string_literal: true

require "test_helper"

class API::V1::EmailTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @candidate = candidates(:john)
    @template = email_templates(:ruby_dev_intro_toughbyte)
    @current_account = accounts(:employee_account)
    sign_in @current_account
  end

  test "should show email template" do
    get api_v1_email_template_url(@template, candidate_id: @candidate.id), as: :json

    assert_response :success

    json_response = JSON.parse(response.body)

    assert_equal json_response["subject"], @template.subject
    assert_equal json_response["message"],
                 "Hi, John!<br>My name is Adrian.<br>" \
                 "Found your profile on and was blown away at your CV.<br>" \
                 "I'm looking for Ruby developer, and you look like a perfect candidate.<br>" \
                 "Tell me if you're interested, and I'll gladly answer all your questions."
  end

  test "should return not found for invalid template" do
    get api_v1_email_template_url(id: "invalid", candidate_id: @candidate.id), as: :json

    assert_response :not_found
  end

  test "should return not found for invalid candidate" do
    get api_v1_email_template_url(@template, candidate_id: "invalid"), as: :json

    assert_response :not_found
  end
end
