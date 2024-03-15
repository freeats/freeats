# frozen_string_literal: true

class CreateCandidateEmailAddresses < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE EXTENSION IF NOT EXISTS citext;
        SQL
      end
    end

    create_table :candidate_email_addresses do |t|
      t.references :candidate, foreign_key: true, null: false, index: false
      t.column :address, :citext, null: false
      t.column :list_index, :integer, null: false
      t.column :type, :candidate_contact_type, null: false
      t.column :source, :candidate_contact_source, null: false, default: "other"
      t.column :status, :candidate_contact_status, null: false, default: "current"
      t.column :url, :string, null: false, default: ""

      t.timestamps

      t.index %i[candidate_id address], unique: true
      t.index %i[candidate_id list_index], unique: true
    end
  end
end
