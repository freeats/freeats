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
end
