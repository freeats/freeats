# frozen_string_literal: true

class CreateJoinTablePositionInterviewer < ActiveRecord::Migration[7.1]
  def change
    create_table :positions_interviewers, id: false do |t|
      t.references :position, foreign_key: true, null: false, index: false
      t.references :interviewer, foreign_key: { to_table: :members }, null: false, index: false

      t.index %i[position_id interviewer_id], unique: true
    end
  end
end
