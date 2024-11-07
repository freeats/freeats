# frozen_string_literal: true

class Tenant < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged, routes: nil

  validates :name, presence: true
  validates :slug, presence: { message: I18n.t("tenants.slug_should_by_present_error") },
                   if: -> { career_site_enabled }

  validate :all_active_positions_have_recruiter_when_career_site_enabled

  def create_mandatory_disqualify_reasons
    %w[no_reply position_closed].each do |title|
      DisqualifyReason.create!(
        tenant_id: id,
        title: title.humanize,
        description: I18n.t("candidates.disqualification.disqualify_statuses.#{title}")
      )
    end
  end

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

  def should_generate_new_friendly_id?
    slug.nil?
  end
end
