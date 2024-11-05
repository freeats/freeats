# frozen_string_literal: true

class CreateDisqualifyReasons < ActiveRecord::Migration[7.1]
  def change
    create_table :disqualify_reasons do |t|
      t.string :title
      t.string :description, null: false, default: ""

      t.timestamps
    end

    add_belongs_to :disqualify_reasons, :tenant, index: true
    add_index :disqualify_reasons, %i[title tenant_id], unique: true

    reversible do |dir|
      dir.up do
        tenant_with_reasons_titles =
          Tenant
          .select("tenants.id AS tenant_id", "array_agg(distinct placements.status) AS titles")
          .joins(
            "LEFT JOIN placements ON placements.tenant_id = tenants.id AND " \
            "placements.status NOT IN ('qualified', 'reserved')"
          )
          .group("tenants.id")
          .map { [ _1.tenant_id, _1.titles.compact ] }.to_h

        %w[no_reply position_closed].each do |reason_title|
          tenant_with_reasons_titles.each_value { _1 << reason_title unless reason_title.in?(_1) }
        end

        tenant_with_reasons_titles.each_pair do |tenant_id, titles|
          titles.each do |title|
            DisqualifyReason.create!(
              tenant_id:,
              title:,
              description: I18n.t("candidates.disqualification.disqualify_statuses.#{title}")
            )
          end
        end
      end
    end
  end
end
