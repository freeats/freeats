# frozen_string_literal: true

class CreateCandidateLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :candidate_links do |t|
      t.references :candidate, foreign_key: true, null: false, index: false
      t.column :url, :string, null: false
      t.column :status, :candidate_contact_status, null: false, default: "current"

      t.timestamps

      t.index %i[candidate_id url], unique: true
    end
  end
end
