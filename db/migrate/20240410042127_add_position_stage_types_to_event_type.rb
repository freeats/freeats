# frozen_string_literal: true

class AddPositionStageTypesToEventType < ActiveRecord::Migration[7.1]
  def up
    execute "ALTER TYPE event_type ADD VALUE 'position_stage_added' BEFORE 'scorecard_template_added';"
    execute "ALTER TYPE event_type ADD VALUE 'position_stage_changed' BEFORE 'scorecard_template_added';"
  end
end
