# frozen_string_literal: true

class Location < ApplicationRecord
  self.inheritance_column = nil
  # self.ignored_columns += %w[
  #   geoname_feature_code
  #   geoname_modification_date
  #   geoname_admin1_code
  #   geoname_admin2_code
  #   geoname_admin3_code
  #   geoname_admin4_code
  # ]

  has_many :hierarchies, class_name: "LocationHierarchy", dependent: :restrict_with_exception
  has_many :children_hierarchies,
           class_name: "LocationHierarchy",
           foreign_key: :parent_location_id,
           dependent: :restrict_with_exception,
           inverse_of: :parent_location
  has_many :location_aliases, dependent: :destroy
  has_one :country,
          -> { where(type: :country) },
          class_name: "Location",
          foreign_key: :country_code,
          primary_key: :country_code,
          inverse_of: false,
          dependent: nil

  enum type: %i[city admin_region2 admin_region1 country set].index_with(&:to_s)

  validates :name, presence: true
  validates :ascii_name, presence: true
  validates :geoname_id, uniqueness: true, allow_nil: true
  validates :type, presence: true

  def self.search_by_name(name, types: self.types.keys, limit: 25)
    BaseQueries.location_search_by_name(
      name,
      types:,
      limit:
    )
  end

  def self.worldwide_mock
    worldwide_location = Location.new

    class << worldwide_location
      def short_name
        "Worldwide"
      end
    end

    worldwide_location
  end

  def short_name
    case type
    when "country", "set"
      name
    else
      "#{name}, #{country_name}"
    end
  end

  def rails_admin_name
    short_name
  end

  def child_of?(parents)
    parent_ids =
      if Array(parents).all? { _1.is_a?(Integer) }
        parents
      else
        Array(parents).map(&:id)
      end

    find_children_sql = <<~SQL.squish
      WITH childen_locations AS (
        SELECT path
        FROM location_hierarchies
        WHERE location_id IN (:child_id)
      )
      SELECT 1
      FROM location_hierarchies lh, childen_locations cl
      WHERE lh.location_id IN (:parent_id)
      AND lh.path != cl.path
      AND lh.path @> cl.path
      LIMIT 1
    SQL
    self.class.find_by_sql([find_children_sql, { child_id: id, parent_id: parent_ids }]).present?
  end

  # @return [Array<Location>] all its parents returned in
  #   ascending order, for example if current location is of type 'city' then the returned
  #   hierarchy could be: [city, admin_region1, country].
  def parents
    self.class.where("id = ANY(location_parents(?))", id)
  end
end
