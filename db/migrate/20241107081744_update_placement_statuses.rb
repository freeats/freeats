# frozen_string_literal: true

class UpdatePlacementStatuses < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      -- add 'disqualified' status
      CREATE TYPE placement_status_new AS ENUM (
        'qualified',
        'reserved',
        'disqualified',
        'availability',
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

      ALTER TABLE placements
        ALTER COLUMN status DROP DEFAULT,
        ALTER COLUMN status TYPE placement_status_new
        USING status::text::placement_status_new;

      UPDATE placements
        SET status = 'disqualified'
        WHERE status NOT IN ('qualified', 'reserved');

      DROP TYPE placement_status;

      ALTER TYPE placement_status_new
        RENAME TO placement_status;

      -- remove undesired statuses
      CREATE TYPE placement_status_new AS ENUM (
        'qualified',
        'reserved',
        'disqualified'
      );

      ALTER TABLE placements
        ALTER COLUMN status SET DEFAULT 'qualified'::placement_status_new,
        ALTER COLUMN status TYPE placement_status_new
        USING status::text::placement_status_new;

      DROP TYPE placement_status;

      ALTER TYPE placement_status_new
        RENAME TO placement_status;
    SQL
  end
end
