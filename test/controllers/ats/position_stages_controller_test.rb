# frozen_string_literal: true

require "test_helper"

class ATS::PositionStagesControllerTest < ActionDispatch::IntegrationTest
  test "should allow to destroy position stage to admins" do
    sign_in accounts(:admin_account)
    position_stage = position_stages(:golang_position_verified)

    assert_not position_stage.deleted

    delete ats_position_stage_path(position_stage),
           params: { delete_stage_modal: "1", new_stage: "Replied" }

    assert position_stage.reload.deleted
    assert_response :ok
  end

  test "should not allow to destroy position stage to non-admins" do
    sign_in accounts(:employee_account)
    position_stage = position_stages(:golang_position_verified)

    assert_not position_stage.deleted

    delete ats_position_stage_path(position_stage),
           params: { delete_stage_modal: "1", new_stage: "Replied" }

    assert_not position_stage.reload.deleted
    assert_response :redirect
    assert_redirected_to "/"
  end

  test "should render error if position stage was not destroyed" do
    sign_in accounts(:admin_account)
    position_stage = position_stages(:golang_position_verified)

    position_stage_destroy_mock = Minitest::Mock.new
    position_stage_destroy_mock.expect(:call, Failure[:position_stage_not_deleted, "error message"])

    PositionStages::Delete.stub(:new, ->(_params) { position_stage_destroy_mock }) do
      err = assert_raises(RenderErrorExceptionForTests) do
        delete(ats_position_stage_path(position_stage), params: { delete_stage_modal: "1" })
      end

      err_info = JSON.parse(err.message)

      assert_equal err_info["message"], "error message"
      assert_equal err_info["status"], "unprocessable_entity"
    end
  end
end
