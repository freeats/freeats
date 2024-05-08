# frozen_string_literal: true

class AddTaskEventsToEventType < ActiveRecord::Migration[7.1]
  def change
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'task_status_changed' AFTER 'sequence_stopped';
      ALTER TYPE event_type ADD VALUE 'task_changed' AFTER 'sequence_stopped';
      ALTER TYPE event_type ADD VALUE 'task_added' AFTER 'sequence_stopped';
    SQL
  end
end
