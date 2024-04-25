# frozen_string_literal: true

class CreateSequenceTemplateStages < ActiveRecord::Migration[7.1]
  def change
    create_table :sequence_template_stages do |t|
      t.references :sequence_template, foreign_key: true, null: false
      t.integer :delay_in_days
      t.integer :position, null: false, default: 1

      t.timestamps
    end
  end
end
