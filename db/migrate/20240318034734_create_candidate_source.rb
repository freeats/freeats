# frozen_string_literal: true

class CreateCandidateSource < ActiveRecord::Migration[7.1]
  def change
    create_table :candidate_sources do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
