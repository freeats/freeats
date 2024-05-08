# frozen_string_literal: true

class CreateJoinTableTaskWatcher < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks_watchers, id: false do |t|
      t.references :task, foreign_key: true, null: false, index: false
      t.references :watcher, foreign_key: { to_table: :members }, null: false, index: false

      t.index %i[task_id watcher_id], unique: true
    end
  end
end
