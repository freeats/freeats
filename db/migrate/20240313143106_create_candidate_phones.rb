# frozen_string_literal: true

class CreateCandidatePhones < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE TYPE public.candidate_contact_type AS ENUM (
              'personal',
              'work'
          );
          CREATE TYPE public.candidate_contact_source AS ENUM (
            'bitbucket',
            'devto',
            'djinni',
            'github',
            'habr',
            'headhunter',
            'hunter',
            'indeed',
            'kendo',
            'linkedin',
            'nymeria',
            'salesql',
            'genderize',
            'toughbyte',
            'other'
          );
          CREATE TYPE public.candidate_contact_status AS ENUM (
              'current',
              'outdated',
              'invalid'
          );
        SQL
      end

      dir.down do
        execute "DROP TYPE candidate_contact_type;"
        execute "DROP TYPE candidate_contact_source;"
        execute "DROP TYPE candidate_contact_status;"
      end
    end

    create_table :candidate_phones do |t|
      t.references :candidate, foreign_key: true, null: false
      t.column :phone, :string, null: false
      t.column :list_index, :integer, null: false
      t.column :type, :candidate_contact_type, null: false
      t.column :source, :candidate_contact_source, null: false, default: "other"
      t.column :status, :candidate_contact_status, null: false, default: "current"

      t.timestamps

      t.index %i[phone candidate_id], unique: true
    end
  end
end
