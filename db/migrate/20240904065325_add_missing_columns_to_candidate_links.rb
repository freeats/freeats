# frozen_string_literal: true

class AddMissingColumnsToCandidateLinks < ActiveRecord::Migration[7.1]
  def change
    add_column :candidate_links, :added_at, :datetime, null: false, default: -> { "clock_timestamp()" }
    add_column :candidate_links, :created_via, :enum, enum_type: :candidate_contact_created_via, null: false, default: :manual
    add_reference :candidate_links, :created_by, foreign_key: { to_table: :members }, index: true
  end
end
