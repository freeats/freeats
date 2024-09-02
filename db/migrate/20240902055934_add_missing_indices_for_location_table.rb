# frozen_string_literal: true

class AddMissingIndicesForLocationTable < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_index :locations, :slug, unique: true
    add_index :locations, :country_name
    add_index :locations, :name

    execute <<~SQL
      CREATE INDEX index_locations_on_name_trgm
      ON locations USING GIN (lower(f_unaccent(name)) gin_trgm_ops);
    SQL
  end

  def down
    remove_index :locations, :slug
    remove_index :locations, :country_name
    remove_index :locations, :name
    remove_index :locations, name: "index_locations_on_name_trgm"
  end
end
