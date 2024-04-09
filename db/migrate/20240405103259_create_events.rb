# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE TYPE public.event_type AS ENUM (
            'position_added',
            'position_changed',
            'position_recruiter_assigned',
            'position_recruiter_unassigned'
          );
        SQL
      end

      dir.down do
        execute "DROP TYPE event_type;"
      end
    end

    create_table :events do |t|
      t.column :type, :event_type, null: false
      t.timestamp :performed_at, null: false, default: -> { "clock_timestamp()" }
      t.references :actor_account, foreign_key: { to_table: :accounts }
      t.string :eventable_type, null: false
      t.integer :eventable_id, null: false
      t.string :changed_field
      t.jsonb :changed_from
      t.jsonb :changed_to
      t.jsonb :properties, null: false, default: {}

      t.timestamps

      t.index %i[eventable_id eventable_type]
    end
  end
end
