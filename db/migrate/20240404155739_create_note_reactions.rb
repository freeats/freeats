# frozen_string_literal: true

class CreateNoteReactions < ActiveRecord::Migration[7.1]
  def change
    create_join_table :members, :notes, table_name: :note_reactions do |t|
      t.index %i[note_id member_id], unique: true
    end
  end
end
