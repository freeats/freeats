# frozen_string_literal: true

class CreatePlacements < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE TYPE public.placement_status AS ENUM (
            'qualified',
            'reserved',
            'location',
            'no_reply',
            'not_interested',
            'other_offer',
            'overpriced',
            'overqualified',
            'position_closed',
            'remote_only',
            'team_fit',
            'underqualified',
            'workload',
            'other'
          );
        SQL
      end

      dir.down do
        execute "DROP TYPE placement_status;"
      end
    end

    create_table :placements do |t|
      t.references :position, null: false, foreign_key: true
      t.references :position_stage, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true
      t.column :status, :placement_status, default: "qualified", null: false
      t.integer :greenhouse_id, index: true

      t.timestamps
    end
  end
end
