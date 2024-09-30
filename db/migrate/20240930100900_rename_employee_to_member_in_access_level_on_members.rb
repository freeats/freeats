# frozen_string_literal: true

class RenameEmployeeToMemberInAccessLevelOnMembers < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      CREATE TYPE public.member_access_level_new AS ENUM (
        'inactive',
        'member',
        'admin'
      );
    SQL

    add_column :members, :access_level_new, :member_access_level_new

    execute <<-SQL
      UPDATE public.members
      SET access_level_new = CASE
        WHEN access_level = 'employee' THEN 'member'::public.member_access_level_new
        ELSE access_level::text::public.member_access_level_new
      END;
    SQL

    remove_column :members, :access_level

    rename_column :members, :access_level_new, :access_level

    execute <<-SQL
      DROP TYPE member_access_level;
      ALTER TYPE member_access_level_new
        RENAME TO member_access_level;
    SQL
  end

  def down
    execute <<-SQL
      CREATE TYPE public.member_access_level_new AS ENUM (
        'inactive',
        'employee',
        'admin'
      );
    SQL

    add_column :members, :access_level_new, :member_access_level_new

    execute <<-SQL
      UPDATE public.members
      SET access_level_new = CASE
        WHEN access_level = 'member' THEN 'employee'::public.member_access_level_new
        ELSE access_level::text::public.member_access_level_new
      END;
    SQL

    remove_column :members, :access_level

    rename_column :members, :access_level_new, :access_level

    execute <<-SQL
      DROP TYPE member_access_level;
      ALTER TYPE member_access_level_new
        RENAME TO member_access_level;
    SQL
  end
end
