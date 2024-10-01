# frozen_string_literal: true

require "test_helper"

class ATS::PlacementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_account = accounts(:employee_account)
    sign_in @current_account
  end

  test "fetch_pipeline_placements should works" do
    get ats_position_fetch_pipeline_placements_path(position_id: positions(:ruby_position).id)

    assert_response :success
  end
end
