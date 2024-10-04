# frozen_string_literal: true

require "test_helper"

class DevopsAuthenticationControllerTest < ActionDispatch::IntegrationTest
  setup do
    # For some reason multiple calling different paths started to stack them,
    # example: `/admin/pghero`, and because of this, we call paths from @routes
    @routes = Rails.application.routes.url_helpers
  end

  test "should return 401 when member is not authorized into application" do
    get @routes.rails_admin_path

    assert_response :unauthorized

    get @routes.pg_hero_path

    assert_response :unauthorized

    get @routes.mission_control_jobs_path

    assert_response :unauthorized

    # check nested routes

    get "/admin/candidates"

    assert_response :unauthorized

    get "/pghero/live_queries"

    assert_response :unauthorized

    get "/jobs/applications/ats/failed/jobs"

    assert_response :unauthorized
  end

  test "should return 401 when member is authorized into application" do
    sign_in accounts(:admin_account)

    get @routes.rails_admin_path

    assert_response :unauthorized

    get @routes.pg_hero_path

    assert_response :unauthorized

    get @routes.mission_control_jobs_path

    assert_response :unauthorized

    # check nested routes

    get "/admin/candidates"

    assert_response :unauthorized

    get "/pghero/live_queries"

    assert_response :unauthorized

    get "/jobs/applications/ats/failed/jobs"

    assert_response :unauthorized
  end
end
