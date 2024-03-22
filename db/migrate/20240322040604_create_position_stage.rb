# frozen_string_literal: true

class CreatePositionStage < ActiveRecord::Migration[7.1]
  def change
    create_table :position_stages do |t|
      t.references :position, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.integer :list_index, null: false
      t.integer :greenhouse_id, index: true

      t.timestamps

      t.index %i[position_id name], unique: true
      t.index %i[position_id list_index], unique: true
    end
  end
end
