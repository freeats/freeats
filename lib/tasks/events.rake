# frozen_string_literal: true

namespace :events do
  task update_positions_new_status: :environment do
    logger = Logger.new($stdout)
    logger.info("Starting update_positions_new_status rake task")

    Event
      .where(eventable_type: "Position", type: "position_changed", changed_field: "status")
      .where(changed_from: "active")
      .in_batches(of: 10_000, use_ranges: true)
      .update_all(changed_from: :open) # rubocop:disable Rails/SkipsModelValidations

    Event
      .where(eventable_type: "Position", type: "position_changed", changed_field: "status")
      .where(changed_to: "active")
      .in_batches(of: 10_000, use_ranges: true)
      .update_all(changed_to: :open) # rubocop:disable Rails/SkipsModelValidations

    logger.info("Done.")
  end
end
