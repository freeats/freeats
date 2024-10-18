# frozen_string_literal: true

class RemoveGreenhouseIdColumnFromAllTables < ActiveRecord::Migration[7.1]
  def up
    remove_column :placements, :greenhouse_id, :integer
    remove_column :position_stages, :greenhouse_id, :integer
    remove_column :scorecard_templates, :greenhouse_id, :integer
    remove_column :scorecards, :greenhouse_id, :integer
  end
end
