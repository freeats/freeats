# frozen_string_literal: true

class AddAttachmentEventsToEventType < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'active_storage_attachment_added' BEFORE 'candidate_added';
      ALTER TYPE event_type ADD VALUE 'active_storage_attachment_removed' BEFORE 'candidate_added';
    SQL
  end
end
