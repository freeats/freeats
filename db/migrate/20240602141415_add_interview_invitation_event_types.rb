# frozen_string_literal: true

class AddInterviewInvitationEventTypes < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'candidate_interview_scheduled' AFTER 'candidate_changed';
      ALTER TYPE event_type ADD VALUE 'candidate_interview_resolved' AFTER 'candidate_changed';
    SQL
  end
end
