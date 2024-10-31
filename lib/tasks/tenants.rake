# frozen_string_literal: true

namespace :tenants do
  task populate_slugs: :environment do
    Log.info("Populating slugs...")

    Tenant.find_each do |tenant|
      tenant.slug = nil
      tenant.save!
      Log.info("Generated tenant slug: #{tenant.slug}")
    rescue StandardError => e
      Log.error("Tenant #{tenant.id} failed with #{e.inspect}.")
    end

    Position.find_each do |position|
      position.slug = nil
      position.save!
      Log.info("Generated position slug: #{position.slug}")
    rescue StandardError => e
      Log.error("Position #{position.id} failed with #{e.inspect}.")
    end

    Log.info("Done.")
  end
end
