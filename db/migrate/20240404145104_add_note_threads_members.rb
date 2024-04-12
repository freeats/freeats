# frozen_string_literal: true

class AddNoteThreadsMembers < ActiveRecord::Migration[7.1]
  create_join_table :note_threads, :members do |t|
    t.index :note_thread_id
    t.index :member_id
  end
end
