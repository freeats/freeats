# frozen_string_literal: true

class CreateNoteThreads < ActiveRecord::Migration[7.1]
  def change
    create_table :note_threads do |t|
      t.references :notable, polymorphic: true, null: false
      t.boolean :hidden, default: false, null: false

      t.timestamps
    end
  end
end
