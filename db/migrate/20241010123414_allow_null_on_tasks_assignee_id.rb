# frozen_string_literal: true

class AllowNullOnTasksAssigneeId < ActiveRecord::Migration[7.1]
  def change
    change_column_null(:tasks, :assignee_id, true)
  end
end
