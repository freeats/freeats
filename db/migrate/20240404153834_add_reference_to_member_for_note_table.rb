# frozen_string_literal: true

class AddReferenceToMemberForNoteTable < ActiveRecord::Migration[7.1]
  def change
    add_reference :notes, :member, foreign_key: true, null: false
  end
end
