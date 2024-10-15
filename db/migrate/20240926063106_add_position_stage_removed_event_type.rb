# frozen_string_literal: true

class AddPositionStageRemovedEventType < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'position_stage_removed' AFTER 'position_stage_changed';
    SQL
  end
end
