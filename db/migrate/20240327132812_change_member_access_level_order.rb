# frozen_string_literal: true

class ChangeMemberAccessLevelOrder < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE member_access_level RENAME TO old_member_access_level;

      CREATE TYPE member_access_level AS
        ENUM ('inactive', 'interviewer', 'hiring_manager', 'employee', 'admin');

      ALTER TABLE members
      ALTER COLUMN access_level TYPE member_access_level
      USING access_level::text::member_access_level;

      DROP TYPE old_member_access_level;
    SQL
  end
end
