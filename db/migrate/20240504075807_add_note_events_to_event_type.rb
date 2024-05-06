# frozen_string_literal: true

class AddNoteEventsToEventType < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'note_added' BEFORE 'placement_added';
      ALTER TYPE event_type ADD VALUE 'note_removed' BEFORE 'placement_added';
    SQL
  end
end
