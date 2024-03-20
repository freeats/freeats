# frozen_string_literal: true

class CreatePositions < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE TYPE public.position_status AS ENUM (
              'draft',
              'active',
              'passive',
              'closed'
          );
          CREATE TYPE public.position_change_status_reason AS ENUM (
              'other',
              'new_position',
              'deprioritized',
              'filled',
              'no_longer_relevant',
              'cancelled'
          );
        SQL
      end
      dir.down do
        execute "DROP TYPE position_status;"
        execute "DROP TYPE position_change_status_reason;"
      end
    end

    create_table :positions do |t|
      t.column :status, :position_status, null: false, default: "draft"
      t.column :name, :string, null: false
      t.column :change_status_reason, :position_change_status_reason, null: false, default: "new_position"

      t.timestamps
    end
  end
end
