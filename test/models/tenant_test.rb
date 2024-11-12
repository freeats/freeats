# frozen_string_literal: true

require "test_helper"

class TenantTest < ActiveSupport::TestCase
  test "should work all_active_positions_have_recruiter_when_career_site_enabled" do
    tenant = tenants(:toughbyte_tenant)

    assert_predicate tenant, :valid?

    tenant.career_site_enabled = true
    # One of the open positions does not have a recruiter (golang_position).
    assert_not tenant.valid?
    assert_equal tenant.errors[:base], [I18n.t("tenants.invalid_positions_error", count: 1)]

    positions(:golang_position).update!(recruiter: members(:hiring_manager_member))

    assert_predicate tenant, :valid?

    positions(:golang_position).update!(recruiter: members(:inactive_member))

    assert_not tenant.valid?
    assert_equal tenant.errors[:base], [I18n.t("tenants.invalid_positions_error", count: 1)]
  end

  test "should validate presence of name" do
    tenant = Tenant.new(name: nil)

    assert_not tenant.valid?
    assert_includes tenant.errors[:name], "can't be blank"

    tenant.name = "Example Tenant"

    assert_predicate tenant, :valid?
  end

  test "models_with_tenant should return table names of all models, associated with tenant" do
    assert_equal Tenant.models_with_tenant.count, 24
    assert_includes Tenant.models_with_tenant, "candidates"
    assert_includes Tenant.models_with_tenant, "positions"
    assert_includes Tenant.models_with_tenant, "scorecards"
    assert_includes Tenant.models_with_tenant, "events"
    assert_includes Tenant.models_with_tenant, "email_threads"
    assert_includes Tenant.models_with_tenant, "candidate_email_addresses"
    assert_includes Tenant.models_with_tenant, "candidate_links"
    assert_includes Tenant.models_with_tenant, "candidate_sources"
    assert_includes Tenant.models_with_tenant, "email_messages"
    assert_includes Tenant.models_with_tenant, "accounts"
    assert_includes Tenant.models_with_tenant, "email_message_addresses"
    assert_includes Tenant.models_with_tenant, "placements"
    assert_includes Tenant.models_with_tenant, "scorecard_questions"
    assert_includes Tenant.models_with_tenant, "scorecard_template_questions"
    assert_includes Tenant.models_with_tenant, "tasks"
    assert_includes Tenant.models_with_tenant, "scorecard_templates"
    assert_includes Tenant.models_with_tenant, "note_threads"
    assert_includes Tenant.models_with_tenant, "notes"
    assert_includes Tenant.models_with_tenant, "position_stages"
    assert_includes Tenant.models_with_tenant, "access_tokens"
    assert_includes Tenant.models_with_tenant, "candidate_phones"
    assert_includes Tenant.models_with_tenant, "members"
    assert_includes Tenant.models_with_tenant, "candidate_alternative_names"
    assert_includes Tenant.models_with_tenant, "disqualify_reasons"
  end

  test "cascade_destroy should destroy tenant and all associated models" do
    tenant = tenants(:toughbyte_tenant)

    assert_raises(ActiveRecord::InvalidForeignKey) do
      tenant.destroy!
    end

    assert_nothing_raised do
      tenant.cascade_destroy
    end
  end
end
