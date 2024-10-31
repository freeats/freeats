# frozen_string_literal: true

class RemoveInterviews < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      -- remove event_types associated with sequences
      CREATE TYPE event_type_new AS ENUM (
        'active_storage_attachment_added',
        'active_storage_attachment_removed',
        'candidate_added',
        'candidate_changed',
        'candidate_merged',
        'candidate_recruiter_assigned',
        'candidate_recruiter_unassigned',
        'email_received',
        'email_sent',
        'note_added',
        'note_removed',
        'placement_added',
        'placement_changed',
        'placement_removed',
        'position_added',
        'position_changed',
        'position_collaborator_assigned',
        'position_collaborator_unassigned',
        'position_hiring_manager_assigned',
        'position_hiring_manager_unassigned',
        'position_interviewer_assigned',
        'position_interviewer_unassigned',
        'position_recruiter_assigned',
        'position_recruiter_unassigned',
        'position_stage_added',
        'position_stage_changed',
        'position_stage_removed',
        'scorecard_added',
        'scorecard_removed',
        'scorecard_template_added',
        'scorecard_template_removed',
        'scorecard_template_updated',
        'scorecard_updated',
        'task_added',
        'task_changed',
        'task_status_changed',
        'task_watcher_added',
        'task_watcher_removed'
      );

      DELETE FROM events
        WHERE type IN ('candidate_interview_resolved', 'candidate_interview_scheduled');

      ALTER TABLE events
        ALTER COLUMN type TYPE event_type_new
        USING type::text::event_type_new;

      DROP TYPE event_type;

      ALTER TYPE event_type_new RENAME TO event_type;
    SQL
  end
end
