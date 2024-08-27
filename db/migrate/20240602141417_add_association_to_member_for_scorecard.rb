# frozen_string_literal: true

class AddAssociationToMemberForScorecard < ActiveRecord::Migration[7.1]
  def change
    remove_column :scorecards, :interviewer, :string
    add_reference :scorecards, :interviewer, foreign_key: { to_table: :members }, null: false, index: false
  end
end
