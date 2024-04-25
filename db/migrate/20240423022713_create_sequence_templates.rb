# frozen_string_literal: true

class CreateSequenceTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :sequence_templates do |t|
      t.references :position, foreign_key: true
      t.string :subject, null: false, default: ""
      t.string :name, null: false, default: ""
      t.boolean :archived, null: false, default: false

      t.timestamps
    end
  end
end
