# frozen_string_literal: true

require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_account = accounts(:employee_account)
    sign_in @current_account
  end

  test "should render 403 error" do
    get "/403"

    assert_response :forbidden
    assert_select "h1", "403 | Unauthorized"

    get "/403", headers: { Accept: "application/json" }

    assert_response :forbidden
    assert_equal response.body, { error: { title: "Unauthorized" } }.to_json

    get "/403", xhr: true

    assert_response :forbidden
    assert_includes response.body, "Unauthorized"
  end

  test "should render 404 error" do
    get "/404"

    assert_response :not_found
    assert_select "h1", "404 | Page not found"

    get "/404", headers: { Accept: "application/json" }

    assert_response :not_found
    assert_equal response.body, { error: { title: "Page Not Found" } }.to_json

    get "/404", xhr: true

    assert_response :not_found
    assert_includes response.body, "Page Not Found"
  end

  test "should render 422 error" do
    get "/422"

    assert_response :unprocessable_entity
    assert_select "h1", "422 | The change you wanted was rejected"

    get "/422", headers: { Accept: "application/json" }

    assert_response :unprocessable_entity
    assert_equal response.body,
                 { error:
                  { title: "The change you wanted was rejected" } }.to_json

    get "/422", xhr: true

    assert_response :unprocessable_entity
    assert_includes response.body, "The change you wanted was rejected."
  end

  test "should render 500 error" do
    get "/500"

    assert_response :internal_server_error
    assert_select "h1", "500 | Application Error"

    get "/500", headers: { Accept: "application/json" }

    assert_response :internal_server_error
    assert_equal response.body, { error: { title: "Application Error." } }.to_json

    get "/500", xhr: true

    assert_response :internal_server_error
    assert_includes response.body, "Application Error."
  end
end
