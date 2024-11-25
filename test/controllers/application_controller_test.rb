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
    assert_select "h1", "Forbidden"
    assert_select "p", "You don't have permission to access this page."

    get "/403", headers: { Accept: "application/json" }

    assert_response :forbidden
    assert_equal response.body, { error: { title: "Forbidden" } }.to_json

    get "/403", xhr: true

    assert_response :forbidden
    assert_includes response.body, "Forbidden"
  end

  test "should render 404 error" do
    get "/404"

    assert_response :not_found
    assert_select "h1", "Not found"
    assert_select "p", "The page you were looking for doesn't exist."

    get "/404", headers: { Accept: "application/json" }

    assert_response :not_found
    assert_equal response.body, { error: { title: "Not found" } }.to_json

    get "/404", xhr: true

    assert_response :not_found
    assert_includes response.body, "Not found"
  end

  test "should render 422 error" do
    get "/422"

    assert_response :unprocessable_entity
    assert_select "h1", "Unprocessable content"
    assert_select "p", "We couldn't process your request because some information is missing or incorrect."

    get "/422", headers: { Accept: "application/json" }

    assert_response :unprocessable_entity
    assert_equal response.body,
                 { error:
                  { title: "Unprocessable content" } }.to_json

    get "/422", xhr: true

    assert_response :unprocessable_entity
    assert_includes response.body, "Unprocessable content"
  end

  test "should render 500 error" do
    get "/500"

    assert_response :internal_server_error
    assert_select "h1", "Internal server error"
    assert_select "p", "Something went wrong, please try again later."

    get "/500", headers: { Accept: "application/json" }

    assert_response :internal_server_error
    assert_equal response.body, { error: { title: "Internal server error" } }.to_json

    get "/500", xhr: true

    assert_response :internal_server_error
    assert_includes response.body, "Internal server error"
  end
end
