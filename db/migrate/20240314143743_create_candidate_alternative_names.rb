# frozen_string_literal: true

class CreateCandidateAlternativeNames < ActiveRecord::Migration[7.1]
  def change
    create_table :candidate_alternative_names do |t|
      t.references :candidate, foreign_key: true, null: false, index: false
      t.column :name, :string, null: false

      t.timestamps

      t.index %i[candidate_id name], unique: true
    end
  end
end
