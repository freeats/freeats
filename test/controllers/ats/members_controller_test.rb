# frozen_string_literal: true

require "test_helper"

class ATS::MembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in accounts(:admin_account)
  end

  test "should get team page and show invite modal" do
    get ats_team_path

    assert_response :success

    get invite_modal_ats_members_path

    assert_response :success
  end

  test "should reactivate member" do
    member = members(:inactive_member)

    assert_predicate member, :inactive?

    patch reactivate_ats_member_path(id: member.account.id)

    assert_redirected_to ats_team_path
    assert_equal flash[:notice],
                 I18n.t("user_accounts.successfully_reactivated", name: member.account.name)
    assert_predicate member.reload, :active?
  end

  test "should not reactivate if member is active" do
    member = members(:hiring_manager_member)

    assert_predicate member, :active?

    err = assert_raises(RenderErrorExceptionForTests) do
      patch(reactivate_ats_member_path(id: member.account.id))
    end

    err_info = JSON.parse(err.message)

    assert_equal err_info["message"], I18n.t(
      "user_accounts.already_has_access_level",
      name: member.account.name,
      access_level: member.access_level
    )
    assert_equal err_info["status"], "unprocessable_entity"
    assert_predicate member.reload, :active?
  end

  test "should deactivate member" do
    member = members(:hiring_manager_member)

    assert_predicate member, :active?

    patch deactivate_ats_member_path(id: member.account.id)

    assert_redirected_to ats_team_path
    assert_equal flash[:notice],
                 I18n.t("user_accounts.successfully_deactivated", name: member.account.name)
    assert_predicate member.reload, :inactive?
  end

  test "should not deactivate self" do
    member = members(:admin_member)

    err = assert_raises(RenderErrorExceptionForTests) do
      patch(deactivate_ats_member_path(id: member.account.id))
    end

    err_info = JSON.parse(err.message)

    assert_equal err_info["message"], I18n.t("user_accounts.deactivate_self_error")
    assert_equal err_info["status"], "unprocessable_entity"
    assert_predicate member.reload, :active?
  end

  test "should not deactivate if member is inactive" do
    member = members(:inactive_member)

    assert_predicate member, :inactive?

    err = assert_raises(RenderErrorExceptionForTests) do
      patch(deactivate_ats_member_path(id: member.account.id))
    end

    err_info = JSON.parse(err.message)

    assert_equal err_info["message"],
                 I18n.t("user_accounts.already_has_inactive_level", name: member.account.name)
    assert_equal err_info["status"], "unprocessable_entity"
    assert_predicate member.reload, :inactive?
  end

  test "should update member access level" do
    member = members(:hiring_manager_member)
    new_access_level = "admin"

    assert_equal member.access_level, "member"

    patch update_level_access_ats_member_path(id: member.account.id, access_level: new_access_level)

    assert_redirected_to ats_team_path
    assert_equal member.reload.access_level, "admin"
    assert_equal flash[:notice],
                 I18n.t("user_accounts.successfully_updated", name: member.account.name, new_access_level:)
  end

  test "should not update member access level if access level is invalid" do
    member = members(:hiring_manager_member)

    assert_equal member.access_level, "member"
    err = assert_raises(RenderErrorExceptionForTests) do
      patch(update_level_access_ats_member_path(id: member.account.id, access_level: "Abracadabra"))
    end

    err_info = JSON.parse(err.message)

    assert_equal err_info["message"],
                 I18n.t("user_accounts.invalid_access_level", new_access_level: "Abracadabra")
    assert_equal err_info["status"], "unprocessable_entity"
    assert_equal member.reload.access_level, "member"
  end

  test "should not update member access level if access level is not changed" do
    member = members(:hiring_manager_member)

    assert_equal member.access_level, "member"

    err = assert_raises(RenderErrorExceptionForTests) do
      patch(update_level_access_ats_member_path(id: member.account.id, access_level: "member"))
    end

    err_info = JSON.parse(err.message)

    assert_equal err_info["message"],
                 I18n.t("user_accounts.already_has_access_level",
                        name: member.name,
                        access_level: "member")
    assert_equal err_info["status"], "unprocessable_entity"
    assert_equal member.reload.access_level, "member"
  end

  test "should send invitation and create access token" do
    email = "test@test.com"
    token_value = "test_token"

    SecureRandom.stub :urlsafe_base64, token_value do
      assert_difference "AccessToken.count" do
        assert_enqueued_emails 1 do
          post invite_ats_members_path(email:)
        end
      end
    end

    assert_redirected_to ats_team_path
    assert_equal flash[:notice],
                 I18n.t("user_accounts.sussessfully_sent_invitation", email:)

    access_token = AccessToken.last

    assert_equal access_token.sent_to, email
    assert_equal access_token.context, "member_invitation"
    assert_equal access_token.hashed_token, Digest::SHA256.digest(token_value)
  end

  test "should not create access token and send invitation if email is invalid" do
    email = "test@test"

    assert_no_difference "AccessToken.count" do
      assert_enqueued_emails(0) do
        err = assert_raises(RenderErrorExceptionForTests) do
          post(invite_ats_members_path(email:))
        end

        err_info = JSON.parse(err.message)

        assert_equal err_info["message"], I18n.t("user_accounts.invalid_email", email:)
        assert_equal err_info["status"], "unprocessable_entity"
      end
    end
  end

  test "should not create access token and send invitation if account already exists" do
    member = members(:hiring_manager_member)
    email = member.account.email

    assert_no_difference "AccessToken.count" do
      assert_enqueued_emails(0) do
        err = assert_raises(RenderErrorExceptionForTests) do
          post(invite_ats_members_path(email:))
        end

        err_info = JSON.parse(err.message)

        assert_equal err_info["message"], I18n.t("user_accounts.already_exists", email:)
        assert_equal err_info["status"], "unprocessable_entity"
      end
    end
  end
end
