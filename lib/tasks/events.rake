# frozen_string_literal: true

namespace :events do
  task update_placement_changed_events: :environment do
    Log.info("Updating placement_changed events...")

    Event
      .where(type: "placement_changed")
      .where(changed_field: "status")
      .where(
        <<~SQL
          changed_to::text NOT IN ('"qualified"', '"reserved"', '"disqualified"') OR
          changed_from::text NOT IN ('"qualified"', '"reserved"', '"disqualified"')
        SQL
      )
      .find_each do |event|
        update_params = {}
        unless event.changed_to.in?(%w[qualified reserved])
          update_params[:changed_to] = "disqualified"
          update_params[:properties] = { reason: event.changed_to.humanize }
        end
        unless event.changed_from.in?(%w[qualified reserved])
          update_params[:changed_from] = "disqualified"
        end

        event.update!(update_params)
      rescue StandardError => e
        Log.error(
          "Event #{event.id} update failed with #{e.inspect}."
        )
      end

    Log.info("Done.")
  end
end
