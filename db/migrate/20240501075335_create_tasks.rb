# frozen_string_literal: true

class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        create_enum :task_status, %i[open closed]
        create_enum :repeat_interval_type, %i[never daily weekly monthly yearly]
      end
      dir.down do
        execute <<~SQL
          DROP TYPE task_status;
          DROP TYPE repeat_interval_type;
        SQL
      end
    end

    create_table :tasks do |t|
      t.string :name, null: false
      t.column :status, :task_status, default: :open, null: false
      t.column :repeat_interval, :repeat_interval_type, default: :never, null: false
      t.text :description, null: false, default: ""
      t.references :taskable, polymorphic: true
      t.references :assignee, foreign_key: { to_table: :members }, null: false
      t.date :due_date, null: false

      t.timestamps
    end

    add_index :tasks, %i[assignee_id due_date], name: "index_tasks_on_assignee_id_and_due_date"
  end
end
