# frozen_string_literal: true

require "test_helper"

class CareerSite::PositionsControllerTest < ActionDispatch::IntegrationTest
  include Dry::Monads[:result]

  test "apply should create candidate, placement and task and assign recruiter if career_site_enabled is true" do
    position = positions(:ruby_position)
    tenant = position.tenant
    file = fixture_file_upload("empty.pdf", "application/pdf")
    candidate_params = { full_name: "John Smith", email: "KdQ5j@example.com", file: }

    post position_apply_path(position_id: position.id), params: candidate_params

    assert_response :not_found

    tenant.career_site_enabled = true
    tenant.save!(validate: false)

    post position_apply_path(position_id: position.id), params: candidate_params

    assert_response :not_found

    host! tenant.domain

    tenant.career_site_enabled = false
    tenant.save!(validate: false)

    post position_apply_path(position_id: position.id), params: candidate_params

    assert_response :not_found

    tenant.career_site_enabled = true
    tenant.save!(validate: false)

    apply_mock = Minitest::Mock.new
    apply_mock.expect(:call, Success())

    Recaptcha.stub(:verify_via_api_call, true) do
      Candidates::Apply.stub(:new, ->(_params) { apply_mock }) do
        post position_apply_path(position_id: position.id), params: candidate_params
      end
    end

    apply_mock.verify

    assert_redirected_to position_path(position.slug)
    assert_equal flash[:notice], I18n.t("career_site.positions.successfully_applied", position_name: position.name)
  end

  test "apply should return error if errors occurred during the process" do
    position = positions(:ruby_position)
    tenant = position.tenant
    file = fixture_file_upload("empty.pdf", "application/pdf")
    candidate_params = { full_name: "John Smith", email: "KdQ5j@example.com", file: }

    tenant.career_site_enabled = true
    tenant.save!(validate: false)

    inactive_assignee_apply_mock = Minitest::Mock.new
    inactive_assignee_apply_mock.expect(:call, Failure[:inactive_assignee, "Assignee is inactive"])

    host! tenant.domain

    err = assert_raises(RenderErrorExceptionForTests) do
      Recaptcha.stub(:verify_via_api_call, true) do
        Candidates::Apply.stub(:new, ->(_params) { inactive_assignee_apply_mock }) do
          post(position_apply_path(position_id: position.id), params: candidate_params)
        end
      end
    end

    inactive_assignee_apply_mock.verify

    err_info = JSON.parse(err.message)

    assert_equal err_info["message"], I18n.t("errors.something_went_wrong")
    assert_equal err_info["status"], "unprocessable_entity"

    error_message = "It is error message"
    candidate_invalid_apply_mock = Minitest::Mock.new
    candidate_invalid_apply_mock.expect(:call, Failure[:candidate_invalid, error_message])

    err = assert_raises(RenderErrorExceptionForTests) do
      Recaptcha.stub(:verify_via_api_call, true) do
        Candidates::Apply.stub(:new, ->(_params) { candidate_invalid_apply_mock }) do
          post(position_apply_path(position_id: position.id), params: candidate_params)
        end
      end
    end

    candidate_invalid_apply_mock.verify

    err_info = JSON.parse(err.message)

    assert_equal err_info["message"], error_message
    assert_equal err_info["status"], "unprocessable_entity"
  end

  test "show should render position if career_site_enabled" do
    position = positions(:ruby_position)
    tenant = position.tenant

    get position_path(position.slug)

    assert_response :not_found

    tenant.career_site_enabled = true
    tenant.save!(validate: false)

    get position_path(position.id)

    assert_response :not_found

    get position_path(position.slug)

    assert_response :not_found

    host! tenant.domain

    get position_path(position.id)

    assert_response :redirect
    assert_redirected_to(position_path(position.slug))

    get position_path(position.slug)

    assert_response :success
  end

  test "index should render positions if career_site_enabled is true and host exists" do
    tenant = tenants(:toughbyte_tenant)
    host! tenant.domain

    get positions_path

    assert_response :not_found

    tenant.career_site_enabled = true
    tenant.save!(validate: false)

    get positions_path

    assert_response :success

    host! "Abracadabra2024"

    get positions_path

    assert_response :not_found
  end
end