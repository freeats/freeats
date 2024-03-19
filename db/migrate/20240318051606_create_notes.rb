# frozen_string_literal: true

class CreateNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :notes do |t|
      t.text :text, null: false, default: ""
      t.references :note_thread, null: false, foreign_key: true

      t.timestamps
    end
  end
end
