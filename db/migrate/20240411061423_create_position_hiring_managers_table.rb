# frozen_string_literal: true

class CreatePositionHiringManagersTable < ActiveRecord::Migration[7.1]
  def change
    create_table :positions_hiring_managers, id: false do |t|
      t.references :position, foreign_key: true, null: false, index: false
      t.references :hiring_manager, foreign_key: { to_table: :members }, null: false, index: false

      t.index %i[position_id hiring_manager_id], unique: true
    end
  end
end
