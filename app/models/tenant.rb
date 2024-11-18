# frozen_string_literal: true

class Tenant < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged, routes: nil

  validates :name, presence: true
  validates :slug, presence: { message: I18n.t("tenants.slug_should_by_present_error") },
                   if: -> { career_site_enabled }

  validate :all_active_positions_have_recruiter_when_career_site_enabled

  def self.tables_with_tenant_id
    query_to_find_all_tables_with_tenant_id =
      <<~SQL
        SELECT t.table_name
        FROM information_schema.tables AS t
        JOIN information_schema.columns AS c
          ON c.table_name = t.table_name
          AND c.table_schema = t.table_schema
        WHERE c.column_name = 'tenant_id'
          AND t.table_schema NOT IN ('information_schema', 'pg_catalog')
          AND t.table_type = 'BASE TABLE'
      SQL
    ActiveRecord::Base.connection.execute(query_to_find_all_tables_with_tenant_id).values.flatten
  end

  def cascade_destroy
    sorted_tables = Tenant.tables_with_tenant_id.sort_by do |table|
      [
        table == "positions" ? 0 : 1,  # positions should be destroyed before members
        table == "scorecards" ? 0 : 1, # scorecards should be destroyed before members
        table == "events" ? 0 : 1      # events should be destroyed before accounts
      ]
    end
    models = sorted_tables.map { Object.const_get(_1.classify) }
    ActiveRecord::Base.transaction do
      models.each do |model|
        model.where(tenant_id: id).find_each(&:destroy!)
      end

      destroy!
    end
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::InvalidForeignKey => e
    errors.add(:base, e.message.to_s)
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
