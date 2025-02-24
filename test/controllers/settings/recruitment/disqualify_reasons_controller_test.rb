# frozen_string_literal: true

require "test_helper"

class Settings::Recruitment::DisqualifyReasonsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_account = accounts(:admin_account)
    sign_in @current_account
  end

  test "should open disqualify reasons recruitment settings" do
    get settings_recruitment_disqualify_reasons_path

    assert_response :success
  end

  test "should add disqualify reason" do
    old_disqualify_reasons =
      DisqualifyReason.not_deleted.where(tenant: tenants(:toughbyte_tenant)).to_a
    new_disqualify_reason_params = { "title" => "Abracadabra", "description" => "Text" }
    current_disqualify_reasons_params =
      old_disqualify_reasons.map.with_index do |reason, idx|
        [(idx + 1).to_s, { "id" => reason.id, "title" => reason.title, "description" => reason.description }]
      end
    params = {
      "tenant" => {
        "disqualify_reasons_attributes" => (
          current_disqualify_reasons_params + [[(old_disqualify_reasons.size + 1).to_s,
                                                new_disqualify_reason_params]]
        ).to_h
      }
    }

    assert_difference "DisqualifyReason.count" do
      post bulk_update_settings_recruitment_disqualify_reasons_path(params)
    end

    assert_response :success

    new_disqualify_reason = DisqualifyReason.find_by(title: new_disqualify_reason_params["title"])

    assert_equal new_disqualify_reason.description, new_disqualify_reason_params["description"]
    assert_equal [*old_disqualify_reasons, new_disqualify_reason].map(&:title).sort,
                 DisqualifyReason.not_deleted.where(tenant: tenants(:toughbyte_tenant))
                                 .pluck(:title).sort
  end

  test "should show modal if remove disqualify reason" do
    old_disqualify_reasons = DisqualifyReason.not_deleted.to_a
    new_disqualify_reasons =
      old_disqualify_reasons.filter { _1.title == "No reply" || _1.title == "Position closed" }
    current_disqualify_reasons_params =
      new_disqualify_reasons.map.with_index do |reason, idx|
        [(idx + 1).to_s,
         { "id" => reason.id, "title" => reason.title, "description" => reason.description }]
      end
    params = {
      "tenant" => {
        "disqualify_reasons_attributes" => current_disqualify_reasons_params.to_h
      }
    }

    assert_no_difference "DisqualifyReason.count" do
      post bulk_update_settings_recruitment_disqualify_reasons_path(params)
    end

    assert_response :success
    assert_includes response.body,
                    "You won’t be able to select reason Availability, but it will " \
                    "still appear for previously disqualified candidates."
  end

  test "should soft delete disqualify reason if modal shown" do
    new_disqualify_reasons =
      [disqualify_reasons(:no_reply_toughbyte),
       disqualify_reasons(:position_closed_toughbyte)]
    removed_disqualify_reason = disqualify_reasons(:availability_toughbyte)
    candidates_with_removed_disqualify_reason =
      Candidate.joins(:placements).where(placements: { disqualify_reason: removed_disqualify_reason }).first

    current_disqualify_reasons_params =
      new_disqualify_reasons.map.with_index do |reason, idx|
        [(idx + 1).to_s,
         { "id" => reason.id, "title" => reason.title, "description" => reason.description }]
      end
    params = {
      modal_shown: "true",
      "tenant" => {
        "disqualify_reasons_attributes" => current_disqualify_reasons_params.to_h
      }
    }

    assert_no_difference "DisqualifyReason.count" do
      post bulk_update_settings_recruitment_disqualify_reasons_path(params)
    end

    assert_response :success

    assert removed_disqualify_reason.reload.deleted

    assert candidates_with_removed_disqualify_reason
      .placements
      .exists?(disqualify_reason_id: removed_disqualify_reason.id)
  end
end
