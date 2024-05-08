# frozen_string_literal: true

class AddPlacementRemovedEventToEventTypes < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'placement_removed' AFTER 'placement_changed';
    SQL
  end
end
