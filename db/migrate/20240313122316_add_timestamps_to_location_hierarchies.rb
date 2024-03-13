# frozen_string_literal: true

class AddTimestampsToLocationHierarchies < ActiveRecord::Migration[7.1]
  def change
    add_column :location_hierarchies, :created_at, :datetime, null: false
    add_column :location_hierarchies, :updated_at, :datetime, null: false
  end
end
