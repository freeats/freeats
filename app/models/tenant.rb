# frozen_string_literal: true

class Tenant < ApplicationRecord
  enum locale: %i[en ru].index_with(&:to_s)

  validates :name, presence: true

  validate :all_active_positions_have_recruiter_when_career_site_enabled

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
end
