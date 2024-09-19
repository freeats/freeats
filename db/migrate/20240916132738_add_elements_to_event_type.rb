# frozen_string_literal: true

class AddElementsToEventType < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'task_watcher_removed' AFTER 'task_status_changed';
      ALTER TYPE event_type ADD VALUE 'task_watcher_added' AFTER 'task_status_changed';
    SQL
  end
end
