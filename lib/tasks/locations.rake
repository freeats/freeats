# frozen_string_literal: true

require "zip"

namespace :locations do
  task fill_in_locations: :environment do
    if ActiveRecord::Base.connection.table_exists?("location_aliases")
      ActiveRecord::Base.connection.execute(
        "TRUNCATE TABLE location_aliases RESTART IDENTITY CASCADE"
      )
    end

    if ActiveRecord::Base.connection.table_exists?("locations")
      ActiveRecord::Base.connection.execute(
        "TRUNCATE TABLE locations RESTART IDENTITY CASCADE"
      )
    end

    if ActiveRecord::Base.connection.table_exists?("location_hierarhies")
      ActiveRecord::Base.connection.execute(
        "TRUNCATE TABLE location_hierarhies RESTART IDENTITY CASCADE"
      )
    end

    locations_csv_path = Rails.root.join("lib/tasks/location_tables.zip")
    items = []
    Zip::File.open(locations_csv_path) do |zipfile|
      CSV.parse(zipfile.read("locations.csv"), headers: true) do |row|
        item = row.to_h

        item.map do |key, value|
          next if value.present?

          item[key] =
            if Location.columns_hash[key].has_default?
              Location.columns_hash[key].default
            elsif Location.columns_hash[key].null
              nil
            else
              ""
            end
        end

        items << item
      end

      # rubocop:disable Rails/SkipsModelValidations
      items.each_slice(10_000) do |batch|
        Location.insert_all(batch)
      end
      # rubocop:enable Rails/SkipsModelValidations

      items = []
      CSV.parse(zipfile.read("location_aliases.csv"), headers: true) do |row|
        item = row.to_h
        items << item
      end

      # rubocop:disable Rails/SkipsModelValidations
      LocationAlias.insert_all(items)
      # rubocop:enable Rails/SkipsModelValidations

      items = []
      CSV.parse(zipfile.read("location_hierarchies.csv"), headers: true) do |row|
        item = row.to_h
        items << item
      end

      # rubocop:disable Rails/SkipsModelValidations
      LocationHierarchy.insert_all(items)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  # After running this task we should remove a backup table if everything is fine
  # by running task `rails locations:remove_location_hierarchies_backup_table`.
  # To restore `location_hierarchies` table from the backup table
  # use `locations:restore_location_hierarchies_from_backup_table` task.
  task recreate_location_hierarchies: :environment do
    HubLog.info("recreate_location_hierarchies task started...")
    missing_hierarchies = Location.where.missing(:hierarchies).pluck(:id)
    if missing_hierarchies.present?
      raise StandardError,
            "Following locations miss location_hierarchies: #{missing_hierarchies.join(', ')}"
    end

    if ActiveRecord::Base.connection.table_exists?("location_hierarchies_backup")
      raise StandardError,
            "location_hierarchies_backup table exists! " \
            "Please run `rails locations:remove_location_hierarchies_backup_table` first!"
    end

    backup_sql = "CREATE TABLE location_hierarchies_backup AS TABLE location_hierarchies;"
    HubLog.info("Backing up location_hierarchies table")
    ActiveRecord::Base.connection.execute(backup_sql)

    HubLog.info("Recreating paths")
    ActiveRecord::Base.connection.execute("SELECT location_hierarchies_recreate_path();")

    HubLog.info("Done")
    HubLog.info("=" * 50)
    HubLog.info("Please run `rails locations:remove_location_hierarchies_backup_table` task " \
                "to remove backup table if everything is fine.")
    HubLog.info("Or run `rails locations:restore_location_hierarchies_from_backup_table` " \
                "task to restore `location_hierarchies` table from the backup table.")
    HubLog.info("=" * 50)
  end

  task remove_location_hierarchies_backup_table: :environment do
    HubLog.info("Removing location_hierarchies_backup table...")

    if ActiveRecord::Base.connection.table_exists?("location_hierarchies_backup")
      ActiveRecord::Migration.drop_table("location_hierarchies_backup")
    else
      HubLog.warn("location_hierarchies_backup table doesn't exist")
    end

    HubLog.info("Done")
  end

  task restore_location_hierarchies_from_backup_table: :environment do
    HubLog.info("Restoring location_hierarchies table from a backup table...")

    unless ActiveRecord::Base.connection.table_exists?("location_hierarchies_backup")
      raise StandardError,
            "location_hierarchies_backup table doesn't exist!"
    end

    ActiveRecord::Base.connection.execute(<<~SQL)
      TRUNCATE TABLE location_hierarchies;

      INSERT INTO location_hierarchies (parent_location_id, location_id, path, created_at, updated_at)
      SELECT parent_location_id, location_id, path, created_at, updated_at
      FROM location_hierarchies_backup;
    SQL

    HubLog.info("Done")
    HubLog.info("Please run `rails locations:remove_location_hierarchies_backup_table` task " \
                "to remove backup table if everything is fine.")
  end

  task fill_location_aliases: :environment do
    logger = Logger.new($stdout)
    logger.info "Started fill_location_aliases task"

    locations = Location.where.missing(:location_aliases).where(type: %i[city country])
    locations.find_each do |location|
      [location.name, location.ascii_name].uniq.each do |location_name|
        LocationAlias.create!(
          location_id: location.id,
          alias: location_name
        )
      rescue StandardError => e
        logger.error "Location #{location.id} for name #{location_name} failed with #{e.inspect}"
      end
      logger.info "Created aliases for location #{location.id}"
    end

    logger.info "Completed fill_location_aliases task"
  end
end
