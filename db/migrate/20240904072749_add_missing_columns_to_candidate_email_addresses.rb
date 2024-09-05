# frozen_string_literal: true

class AddMissingColumnsToCandidateEmailAddresses < ActiveRecord::Migration[7.1]
  def change
    add_column :candidate_email_addresses, :added_at, :datetime, null: false, default: -> { "clock_timestamp()" }
    add_column :candidate_email_addresses, :created_via, :enum, enum_type: :candidate_contact_created_via, null: false, default: :manual
    add_reference :candidate_email_addresses, :created_by, foreign_key: { to_table: :members }, index: true
  end
end
