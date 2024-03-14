# frozen_string_literal: true

class UpdateCandidateContactSourceEnum < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE candidate_contact_source RENAME TO candidate_contact_source_old;
      CREATE TYPE candidate_contact_source
        AS ENUM(
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
          'other'
        );
      ALTER TABLE candidate_phones
        ALTER COLUMN source DROP DEFAULT,
        ALTER COLUMN source TYPE candidate_contact_source USING source::text::candidate_contact_source,
        ALTER COLUMN source SET DEFAULT 'other'::public.candidate_contact_source;
      DROP TYPE candidate_contact_source_old;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TYPE candidate_contact_source RENAME TO candidate_contact_source_old;
      CREATE TYPE candidate_contact_source
        AS ENUM(
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
      ALTER TABLE candidate_phones
        ALTER COLUMN source DROP DEFAULT,
        ALTER COLUMN source TYPE candidate_contact_source USING source::text::candidate_contact_source,
        ALTER COLUMN source SET DEFAULT 'other'::public.candidate_contact_source;
      DROP TYPE candidate_contact_source_old;
    SQL
  end
end
