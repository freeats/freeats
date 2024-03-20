# frozen_string_literal: true

module Locatable
  extend ActiveSupport::Concern

  IN_LOCATION_QUERY = <<~SQL
    EXISTS (
      SELECT 1
      FROM location_hierarchies
      WHERE path <@ ANY (SELECT path FROM location_hierarchies WHERE location_id IN (:location_ids))
      AND location_id = %s.location_id
      LIMIT 1
    )
  SQL

  included do
    scope :in_location, ->(location_ids, table_name = nil) {
      return if location_ids.blank?

      where(
        ActiveRecord::Base.sanitize_sql_array([IN_LOCATION_QUERY, table_name || self.table_name]),
        location_ids:
      )
    }
  end
end
