# frozen_string_literal: true

class CreateLocations < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up do
        execute "CREATE EXTENSION IF NOT EXISTS ltree;"
        execute "CREATE EXTENSION IF NOT EXISTS unaccent;"

        execute <<~SQL
          CREATE TYPE location_type AS ENUM (
            'city',
            'admin_region2',
            'admin_region1',
            'country',
            'set'
          );
        SQL

        execute <<~SQL
          CREATE OR REPLACE FUNCTION f_unaccent(text) RETURNS text AS
            $func$
                SELECT public.unaccent('public.unaccent', $1)
            $func$
          LANGUAGE sql IMMUTABLE;

          CREATE FUNCTION array_deduplicate(input_array anyarray) RETURNS anyarray
                LANGUAGE plpgsql
                AS $$
            BEGIN
              RETURN ARRAY(SELECT DISTINCT unnest(input_array));
            END
          $$;

          CREATE FUNCTION location_name_to_label(location_name text) RETURNS text AS $$
            BEGIN
              RETURN regexp_replace(f_unaccent(location_name), '[^A-Za-z0-9_]', '_', 'g');
            END;
          $$ LANGUAGE plpgsql IMMUTABLE;

          CREATE FUNCTION location_expand_sets(location_ids bigint[]) RETURNS bigint[] AS $$
            DECLARE
              sets bigint[];
            BEGIN
              sets := (SELECT array_agg(id) FROM locations WHERE id = ANY(location_ids) AND type = 'set');

              IF sets IS NULL THEN
                RETURN location_ids;
              END iF;

              RETURN (
                WITH result_ids AS (
                  WITH RECURSIVE lh(location_id) AS (
                    SELECT location_id
                    FROM location_hierarchies
                    WHERE parent_location_id = ANY(sets)
                    UNION
                    SELECT location_hierarchies.location_id
                    FROM location_hierarchies, lh
                    JOIN locations l ON l.id = lh.location_id
                    WHERE parent_location_id = lh.location_id
                    AND l.type = 'set'
                  )
                  SELECT lh.location_id FROM lh
                )
                SELECT array_agg(id)
                FROM locations
                WHERE id IN (SELECT location_id FROM result_ids)
                AND type != 'set'
              );
            END;
          $$ LANGUAGE plpgsql IMMUTABLE;

          CREATE FUNCTION location_parents(loc_id bigint) RETURNS bigint[] AS $$
            BEGIN
              RETURN (
                WITH location_path AS (
                    SELECT array_agg(path) as paths
                    FROM location_hierarchies
                    WHERE location_id = loc_id
                )
                SELECT array_deduplicate(array_agg(location_id))
                FROM location_hierarchies
                WHERE path @> ANY(SELECT paths from location_path)
                AND location_id != loc_id
              );
            END;
          $$ LANGUAGE plpgsql IMMUTABLE;
        SQL
      end
      dir.down do
        execute "DROP TYPE location_type;"
        execute "DROP FUNCTION f_unaccent;"
        execute "DROP FUNCTION array_deduplicate;"
        execute "DROP FUNCTION location_name_to_label;"
        execute "DROP FUNCTION location_expand_sets;"
        execute "DROP FUNCTION location_parents;"
      end
    end

    create_table :locations do |t|
      t.column :geoname_id, :integer, null: true
      t.column :type, :location_type, null: false
      t.column :name, :string, null: false
      t.column :ascii_name, :string, null: false
      t.column :slug, :string, null: true
      t.column :country_code, :string, null: false
      t.column :country_name, :string, null: false, default: ""
      t.column :latitude, :decimal, precision: 10, scale: 7, null: true
      t.column :longitude, :decimal, precision: 10, scale: 7, null: true
      t.column :population, :integer, null: false, default: 0
      t.column :time_zone, :string, null: false, default: ""
      t.column :linkedin_geourn, :integer, null: true
      t.column :geoname_feature_code, :string, null: false, default: ""
      t.column :geoname_admin1_code, :string, null: false, default: ""
      t.column :geoname_admin2_code, :string, null: false, default: ""
      t.column :geoname_admin3_code, :string, null: false, default: ""
      t.column :geoname_admin4_code, :string, null: false, default: ""
      t.column :geoname_modification_date, :date, null: true

      t.timestamps

      t.index :geoname_id, unique: true
      t.index :type
      t.index :country_code
      t.index :geoname_feature_code
      t.index :geoname_admin1_code
      t.index :geoname_admin2_code
      t.index :geoname_admin3_code
      t.index :geoname_admin4_code
    end

    create_table :location_hierarchies do |t|
      t.references :parent_location, foreign_key: { to_table: :locations }
      t.references :location, foreign_key: true, null: false
      t.column :path, :ltree, null: false

      t.index :path, unique: true
    end

    create_table :location_aliases do |t|
      t.references :location, null: false, foreign_key: true
      t.string :alias, null: false

      t.timestamps

      t.index %i[location_id alias], unique: true
    end
  end
end
