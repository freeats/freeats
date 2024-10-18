# frozen_string_literal: true

class Tenant < ApplicationRecord
  validates :name, presence: true

  validate :all_active_positions_have_recruiter_when_career_site_enabled
  validate :domain_or_subdomain_should_by_present, if: -> { career_site_enabled }

  private

  def all_active_positions_have_recruiter_when_career_site_enabled
    return unless career_site_enabled

    open_positions = Position.open.where(tenant_id: id).left_joins(:recruiter)
    invalid_positions_count =
      open_positions.where(recruiter_id: nil).or(
        open_positions.where(recruiter: { access_level: :inactive })
      ).count

    return if invalid_positions_count.zero?

    errors.add(:base, I18n.t("tenants.invalid_positions_error", count: invalid_positions_count))
  end

  def domain_or_subdomain_should_by_present
    return if domain.present? || subdomain.present?

    errors.add(:base,
               I18n.t("tenants.domain_or_subdomain_should_by_present_error"))
  end
end
