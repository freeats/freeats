# frozen_string_literal: true

class AddExternalSourceIdToExportedTables < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :external_source_id, :bigint
    add_column :positions, :external_source_id, :bigint
    add_column :placements, :external_source_id, :bigint
    add_column :position_stages, :external_source_id, :bigint
    add_column :candidates, :external_source_id, :bigint
    add_column :email_threads, :external_source_id, :bigint
    add_index :candidates, :external_source_id, unique: true
    add_index :positions, :external_source_id, unique: true
    # In Huntflow the stages are same for each position, so ids are not uniq.
    add_index :position_stages, :external_source_id
    add_index :accounts, :external_source_id, unique: true
    add_index :placements, :external_source_id, unique: true
    add_index :email_threads, :external_source_id, unique: true
  end
end
