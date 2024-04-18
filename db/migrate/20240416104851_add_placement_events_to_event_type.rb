# frozen_string_literal: true

class AddPlacementEventsToEventType < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'placement_added' BEFORE 'position_added';
      ALTER TYPE event_type ADD VALUE 'placement_changed' BEFORE 'position_added';
    SQL
  end
end
