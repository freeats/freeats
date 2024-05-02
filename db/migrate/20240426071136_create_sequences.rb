# frozen_string_literal: true

class CreateSequences < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE TYPE public.sequence_status AS ENUM (
          'running',
          'replied',
          'exited',
          'stopped'
      );
    SQL

    create_table :sequences do |t|
      t.references :member_email_address, foreign_key: true, null: false
      t.references :placement, foreign_key: true, null: false
      t.references :sequence_template, foreign_key: true, null: false
      t.references :email_thread
      t.citext :to, null: false
      t.integer :current_stage, null: false, default: 0
      t.timestamp :scheduled_at, null: false
      t.timestamp :started_at
      t.timestamp :exited_at
      t.jsonb :data, null: false, default: {}
      t.jsonb :parameters, null: false, default: {}
      t.column :status, :sequence_status, null: false, default: "running"

      t.timestamps
    end

    execute <<~SQL
      ALTER TABLE sequences
      ADD CONSTRAINT current_stage_must_not_be_negative
      CHECK (current_stage >= 0);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE sequences DROP CONSTRAINT current_stage_must_not_be_negative;
    SQL
    drop_table :sequences
    execute "DROP TYPE sequence_status;"
  end
end
