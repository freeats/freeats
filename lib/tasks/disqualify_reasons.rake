# frozen_string_literal: true

namespace :disqualify_reasons do
  task populate_disqualify_reasons: :environment do
    Log.info("Populating disqualify_reasons...")

    tenant_with_reasons_titles =
      Tenant
      .select("tenants.id AS tenant_id", "array_agg(distinct placements.status) AS titles")
      .joins(
        "LEFT JOIN placements ON placements.tenant_id = tenants.id AND " \
        "placements.status NOT IN ('qualified', 'reserved')"
      )
      .group("tenants.id")
      .to_h { [_1.tenant_id, _1.titles.compact] }

    %w[no_reply position_closed].each do |reason_title|
      tenant_with_reasons_titles.each_value { _1 << reason_title unless reason_title.in?(_1) }
    end

    tenant_with_reasons_titles.each_pair do |tenant_id, titles|
      titles.each do |title|
        if DisqualifyReason.find_by(tenant_id:, title:).blank?
          DisqualifyReason.create!(
            tenant_id:,
            title: title.humanize,
            description: I18n.t("candidates.disqualification.disqualify_statuses.#{title}")
          )
        end
      rescue StandardError => e
        Log.error(
          "DisqualifyReason for tenant #{tenant_id} and title #{title} failed with #{e.inspect}."
        )
      end
    end
    Log.info("Done.")
  end
end
