# frozen_string_literal: true

class CreateScorecards < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE TYPE public.scorecard_score AS ENUM (
            'irrelevant',
            'relevant',
            'good',
            'perfect'
          );
        SQL
      end

      dir.down do
        execute "DROP TYPE scorecard_score;"
      end
    end

    create_table :scorecards do |t|
      t.references :position_stage, null: false, foreign_key: true
      t.references :placement, null: false, foreign_key: true
      t.string :title, null: false
      t.string :interviewer, null: false
      t.column :score, :scorecard_score, null: false
      t.integer :greenhouse_id, index: true
      t.boolean :visible_to_interviewer, null: false, default: false

      t.timestamps
    end
  end
end
