# frozen_string_literal: true

class AddMoreAssignAndUnassignEvents < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'position_interviewer_unassigned' AFTER 'position_changed';
      ALTER TYPE event_type ADD VALUE 'position_interviewer_assigned' AFTER 'position_changed';
      ALTER TYPE event_type ADD VALUE 'position_hiring_manager_unassigned' AFTER 'position_changed';
      ALTER TYPE event_type ADD VALUE 'position_hiring_manager_assigned' AFTER 'position_changed';
      ALTER TYPE event_type ADD VALUE 'position_collaborator_unassigned' AFTER 'position_changed';
      ALTER TYPE event_type ADD VALUE 'position_collaborator_assigned' AFTER 'position_changed';
    SQL
  end
end
