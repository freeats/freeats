# frozen_string_literal: true

class CreateCandidates < ActiveRecord::Migration[7.1]
  def change
    create_table :candidates do |t|
      t.belongs_to :recruiter
      t.belongs_to :location
      t.string :full_name, null: false
      t.string :company
      t.integer :merged_to
      t.timestamp :resume_updated_at
      t.timestamp :last_activity_at, null: false, default: -> { "clock_timestamp()" }
      t.boolean :dont_contant, default: false, null: false
      t.timestamps
    end
  end
end
