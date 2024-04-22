# frozen_string_literal: true

class AddEventsToEventType < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'candidate_added' BEFORE 'position_added';
      ALTER TYPE event_type ADD VALUE 'candidate_changed' BEFORE 'position_added';
      ALTER TYPE event_type ADD VALUE 'candidate_merged' BEFORE 'position_added';
      ALTER TYPE event_type ADD VALUE 'candidate_recruiter_assigned' BEFORE 'position_added';
      ALTER TYPE event_type ADD VALUE 'candidate_recruiter_unassigned' BEFORE 'position_added';
    SQL
  end
end
