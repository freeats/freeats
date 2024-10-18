# frozen_string_literal: true

class RemoveSequences < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      -- remove 'internal_sequence' type
      CREATE TYPE email_message_sent_via_new AS ENUM (
        'gmail',
        'internal_compose',
        'internal_reply'
      );

      UPDATE email_messages
        SET sent_via = 'internal_compose'
        WHERE sent_via = 'internal_sequence';

      ALTER TABLE email_messages
        ALTER COLUMN sent_via TYPE email_message_sent_via_new
        USING sent_via::text::email_message_sent_via_new;

      DROP TYPE email_message_sent_via;

      ALTER TYPE email_message_sent_via_new RENAME TO email_message_sent_via;

      -- remove event_types associated with sequences
      CREATE TYPE event_type_new AS ENUM (
        'active_storage_attachment_added',
        'active_storage_attachment_removed',
        'candidate_added',
        'candidate_changed',
        'candidate_interview_resolved',
        'candidate_interview_scheduled',
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
        WHERE type IN ('sequence_exited', 'sequence_initialized', 'sequence_replied',
                       'sequence_resumed', 'sequence_started', 'sequence_stopped');

      ALTER TABLE events
        ALTER COLUMN type TYPE event_type_new
        USING type::text::event_type_new;

      DROP TYPE event_type;

      ALTER TYPE event_type_new RENAME TO event_type;

      DROP TABLE sequences;
      DROP TABLE sequence_template_stages;
      DROP TABLE sequence_templates;
      DROP TYPE sequence_status;
    SQL
  end
end
