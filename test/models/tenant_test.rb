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

  test "tables_with_tenant_id should return table names of all models, associated with tenant" do
    assert_equal Tenant.tables_with_tenant_id.count, 24
    assert_includes Tenant.tables_with_tenant_id, "candidates"
    assert_includes Tenant.tables_with_tenant_id, "positions"
    assert_includes Tenant.tables_with_tenant_id, "scorecards"
    assert_includes Tenant.tables_with_tenant_id, "events"
    assert_includes Tenant.tables_with_tenant_id, "email_threads"
    assert_includes Tenant.tables_with_tenant_id, "candidate_email_addresses"
    assert_includes Tenant.tables_with_tenant_id, "candidate_links"
    assert_includes Tenant.tables_with_tenant_id, "candidate_sources"
    assert_includes Tenant.tables_with_tenant_id, "email_messages"
    assert_includes Tenant.tables_with_tenant_id, "accounts"
    assert_includes Tenant.tables_with_tenant_id, "email_message_addresses"
    assert_includes Tenant.tables_with_tenant_id, "placements"
    assert_includes Tenant.tables_with_tenant_id, "scorecard_questions"
    assert_includes Tenant.tables_with_tenant_id, "scorecard_template_questions"
    assert_includes Tenant.tables_with_tenant_id, "tasks"
    assert_includes Tenant.tables_with_tenant_id, "scorecard_templates"
    assert_includes Tenant.tables_with_tenant_id, "note_threads"
    assert_includes Tenant.tables_with_tenant_id, "notes"
    assert_includes Tenant.tables_with_tenant_id, "position_stages"
    assert_includes Tenant.tables_with_tenant_id, "access_tokens"
    assert_includes Tenant.tables_with_tenant_id, "candidate_phones"
    assert_includes Tenant.tables_with_tenant_id, "members"
    assert_includes Tenant.tables_with_tenant_id, "candidate_alternative_names"
    assert_includes Tenant.tables_with_tenant_id, "disqualify_reasons"
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
