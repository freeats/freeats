# frozen_string_literal: true

class AddMissingColumnsToCandidatePhones < ActiveRecord::Migration[7.1]
  def change
    create_enum :candidate_contact_created_via, %i[api manual]

    add_column :candidate_phones, :added_at, :datetime, null: false, default: -> { "clock_timestamp()" }
    add_column :candidate_phones, :created_via, :enum, enum_type: :candidate_contact_created_via, null: false, default: :manual
    add_reference :candidate_phones, :created_by, foreign_key: { to_table: :members }, index: true
  end
end
