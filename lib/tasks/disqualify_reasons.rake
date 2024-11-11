# frozen_string_literal: true

namespace :disqualify_reasons do
  task populate_disqualify_reasons: :environment do
    Log.info("Populating disqualify_reasons...")

    disqualify_reasons =
      %w[availability team_fit remote_only location no_reply not_interested workload other_offer
         overpriced overqualified underqualified position_closed other].freeze

    Tenant.select(:id).find_each do |tenant|
      disqualify_reasons.each do |reason|
        title = reason.humanize
        if DisqualifyReason.find_by(tenant_id: tenant.id, title:).blank?
          DisqualifyReason.create!(
            tenant_id: tenant.id,
            title:,
            description: I18n.t("candidates.disqualification.disqualify_statuses.#{reason}")
          )
        end
      rescue StandardError => e
        Log.error(
          "DisqualifyReason for tenant #{tenant.id} and title #{title} failed with #{e.inspect}."
        )
      end
    end
    Log.info("Done.")
  end
end
