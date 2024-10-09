# frozen_string_literal: true

class RenamePositionStatusEnumActiveToOpen < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      CREATE TYPE new_position_status AS ENUM (
        'draft',
        'open',
        'on_hold',
        'closed');
    SQL

    add_column :positions, :new_status, :enum,
               enum_type: :new_position_status,
               null: false, default: "draft"

    execute <<-SQL
      UPDATE public.positions
      SET new_status = CASE
        WHEN status = 'active' THEN 'open'::public.new_position_status
        ELSE status::text::public.new_position_status
      END;
    SQL

    remove_column :positions, :status
    rename_column :positions, :new_status, :status

    execute <<-SQL
      DROP TYPE position_status;
      ALTER TYPE new_position_status
        RENAME TO position_status;
    SQL
  end

  def down
    execute <<-SQL
      CREATE TYPE new_position_status AS ENUM (
        'draft',
        'active',
        'on_hold',
        'closed');
    SQL
    add_column :positions, :new_status, :enum,
               enum_type: :new_position_status,
               null: false, default: "draft"

    execute <<-SQL
      UPDATE public.positions
      SET new_status = CASE
        WHEN status = 'open' THEN 'active'::public.new_position_status
        ELSE status::text::public.new_position_status
      END;
    SQL

    remove_column :positions, :status
    rename_column :positions, :new_status, :status

    execute <<-SQL
      DROP TYPE position_status;
      ALTER TYPE new_position_status
        RENAME TO position_status;
    SQL
  end
end
