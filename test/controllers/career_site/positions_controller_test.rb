# frozen_string_literal: true

require "test_helper"

class CareerSite::PositionsControllerTest < ActionDispatch::IntegrationTest
  include Dry::Monads[:result]

  test "apply should create candidate, placement and task and assign recruiter if career_site_enabled is true" do
    position = positions(:ruby_position)
    tenant = position.tenant
    file = fixture_file_upload("empty.pdf", "application/pdf")
    candidate_params =
      { full_name: "John Smith", email: "KdQ5j@example.com", file:, recaptcha_v3_score: 1.0 }
    tenant_slug = tenant.slug

    assert_equal tenant.career_site_enabled, false

    post(apply_career_site_position_path(tenant_slug:, position_id: position.id),
         params: candidate_params)

    assert_response :not_found

    tenant.career_site_enabled = true
    tenant.save!(validate: false)

    post(apply_career_site_position_path(tenant_slug:, position_id: position.id),
         params: candidate_params)

    assert_redirected_to career_site_position_path(tenant_slug:, id: position.slug)

    apply_mock = Minitest::Mock.new
    apply_mock.expect(:call, Success())

    Recaptcha.stub(:verify_via_api_call, true) do
      Candidates::Apply.stub(:new, ->(_params) { apply_mock }) do
        post(apply_career_site_position_path(tenant_slug:, position_id: position.id),
             params: candidate_params)
      end
    end

    apply_mock.verify

    assert_redirected_to career_site_position_path(tenant_slug:, id: position.slug)
    assert_equal flash[:notice], I18n.t("career_site.positions.successfully_applied", position_name: position.name)
  end

  test "apply should return error if errors occurred during the process" do
    position = positions(:ruby_position)
    tenant = position.tenant
    file = fixture_file_upload("empty.pdf", "application/pdf")
    candidate_params =
      { full_name: "John Smith", email: "KdQ5j@example.com", file:, recaptcha_v3_score: 1.0 }

    tenant.career_site_enabled = true
    tenant.save!(validate: false)

    inactive_assignee_apply_mock = Minitest::Mock.new
    inactive_assignee_apply_mock.expect(:call, Failure[:inactive_assignee, "Assignee is inactive"])

    err = assert_raises(RenderErrorExceptionForTests) do
      Recaptcha.stub(:verify_via_api_call, true) do
        Candidates::Apply.stub(:new, ->(_params) { inactive_assignee_apply_mock }) do
          post(apply_career_site_position_path(tenant_slug: tenant.slug, position_id: position.id),
               params: candidate_params)
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
          post(apply_career_site_position_path(tenant_slug: tenant.slug, position_id: position.id),
               params: candidate_params)
        end
      end
    end

    candidate_invalid_apply_mock.verify

    err_info = JSON.parse(err.message)

    assert_equal err_info["message"], error_message
    assert_equal err_info["status"], "unprocessable_entity"
  end

  test "show should render position if career_site_enabled" do
    # These ENV variables are needed to test the display of the footer on career site when they are defined.
    # The functionality in the absence of these values ​​is checked in the index test.
    ENV["PRIVACY_LINK"] = "example.com/privacy"
    ENV["TERMS_LINK"] = "example.com/terms"
    position = positions(:ruby_position)
    tenant = position.tenant
    tenant_slug = tenant.slug

    get career_site_position_path(tenant_slug:, id: position.slug)

    assert_response :not_found

    tenant.career_site_enabled = true
    tenant.save!(validate: false)

    get career_site_position_path(tenant_slug:, id: position.id)

    assert_response :redirect
    assert_redirected_to(career_site_position_path(tenant_slug:, id: position.slug))

    get career_site_position_path(tenant_slug:, id: position.slug)

    assert_response :success

    ENV["PRIVACY_LINK"] = nil
    ENV["TERMS_LINK"] = nil
  end

  test "index should render positions if career_site_enabled is true and host exists" do
    tenant = tenants(:toughbyte_tenant)

    # Not defined in this test to test the footer when they are missing.
    # The functionality in the presence of these values ​​is checked in the show test.
    assert_nil  ENV.fetch("TERMS_LINK", nil)
    assert_nil  ENV.fetch("PRIVACY_LINK", nil)

    get career_site_positions_path(tenant.slug)

    assert_response :not_found

    tenant.career_site_enabled = true
    tenant.save!(validate: false)

    get career_site_positions_path(tenant.slug)

    assert_response :success

    get career_site_positions_path("Abracadabra2024")

    assert_response :not_found
  end
end
