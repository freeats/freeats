# frozen_string_literal: true

class RemoveInterviewerAndHiringManagerRoles < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE TYPE member_access_level_new AS ENUM (
        'inactive',
        'employee',
        'admin'
      );

      UPDATE members
        SET access_level = 'employee'
        WHERE access_level IN ('interviewer', 'hiring_manager');

      ALTER TABLE members
        ALTER COLUMN access_level TYPE member_access_level_new
        USING access_level::text::member_access_level_new;

      DROP TYPE member_access_level;

      ALTER TYPE member_access_level_new RENAME TO member_access_level;

      ALTER TABLE scorecard_templates
        DROP COLUMN visible_to_interviewer;

      ALTER TABLE scorecards
        DROP COLUMN visible_to_interviewer;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TYPE member_access_level ADD VALUE IF NOT EXISTS 'hiring_manager' AFTER 'inactive';
      ALTER TYPE member_access_level ADD VALUE IF NOT EXISTS 'interviewer' AFTER 'inactive';

      ALTER TABLE scorecard_templates
        ADD COLUMN visible_to_interviewer boolean DEFAULT false NOT NULL;

      ALTER TABLE scorecards
        ADD COLUMN visible_to_interviewer boolean DEFAULT false NOT NULL;
    SQL
  end
end
