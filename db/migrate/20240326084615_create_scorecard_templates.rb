# frozen_string_literal: true

class CreateScorecardTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :scorecard_templates do |t|
      t.references :position_stage, null: false, foreign_key: true, index: { unique: true }
      t.string :title, null: false
      t.integer :greenhouse_id, index: true
      t.boolean :visible_to_interviewer, null: false, default: false

      t.timestamps
    end
  end
end
