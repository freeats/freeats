# frozen_string_literal: true

class AddReferenceToMemberForPosition < ActiveRecord::Migration[7.1]
  def change
    add_reference :positions, :recruiter, foreign_key: { to_table: :members }
  end
end
