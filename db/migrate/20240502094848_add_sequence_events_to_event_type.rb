# frozen_string_literal: true

class AddSequenceEventsToEventType < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE TYPE public.new_event_type AS ENUM (
        'active_storage_attachment_added',
        'active_storage_attachment_removed',
        'candidate_added',
        'candidate_changed',
        'candidate_merged',
        'candidate_recruiter_assigned',
        'candidate_recruiter_unassigned',
        'email_received',
        'email_sent',
        'placement_added',
        'placement_changed',
        'position_added',
        'position_changed',
        'position_recruiter_assigned',
        'position_recruiter_unassigned',
        'position_stage_added',
        'position_stage_changed',
        'scorecard_added',
        'scorecard_template_added',
        'scorecard_template_updated',
        'scorecard_updated',
        'sequence_exited',
        'sequence_initialized',
        'sequence_replied',
        'sequence_resumed',
        'sequence_started',
        'sequence_stopped'
      );
    SQL

    change_column :events, :type, :new_event_type, using: "type::text::new_event_type"

    execute <<~SQL
      DROP TYPE event_type;
      ALTER TYPE new_event_type RENAME TO event_type;
    SQL
  end
end
