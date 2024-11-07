# frozen_string_literal: true

namespace :events do
  task update_placement_changed_events: :environment do
    Log.info("Updating placement_changed events...")

    Event
      .where(type: "placement_changed")
      .where("changed_to::text NOT IN ('qualified', 'reserved') OR " \
             "changed_from::text NOT IN ('qualified', 'reserved')")
      .where("changed_to::text != '\"disqualified\"' AND changed_from::text != '\"disqualified\"'")
      .find_each do |event|
        update_params = {}
        unless event.changed_to.in?(%w[qualified reserved])
          update_params[:changed_to] = "disqualified"
          update_params[:properties] = { title: event.changed_to }
        end
        unless event.changed_from.in?(%w[qualified reserved])
          update_params[:changed_from] = "disqualified"
        end

        event.update!(update_params)
      end

    Log.info("Done.")
  end
end
