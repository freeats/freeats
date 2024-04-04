# frozen_string_literal: true

class AddIndexOnLocationAliases < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE EXTENSION IF NOT EXISTS pg_trgm;

      CREATE INDEX index_location_aliases_on_alias
      ON location_aliases USING btree (alias);

      CREATE INDEX index_location_aliases_on_alias_trgm
      ON location_aliases USING GIN (lower(f_unaccent(alias)) gin_trgm_ops);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX index_location_aliases_on_alias;
      DROP INDEX index_location_aliases_on_alias_trgm;
    SQL
  end
end
