# frozen_string_literal: true

# Current deficiencies:
# - Region can be parsed as city: Stockholm County is parsed as Stockholm city.
# - When only region is present - it fails to parse anything.
# - "Washington, District of Columbia, United States" -> "Colombia"
class LocationParser
  # Characters only in the role of splittable prefixes.
  SIMPLE_PRE = ["¿", "¡"].freeze

  # Characters only in the role of splittable suffixes.
  SIMPLE_POST = ["!", "?", ",", ":", ";", ".", "…"].freeze

  # Characters as splittable prefixes with an optional matching suffix.
  PAIR_PRE = ["(", "{", "[", "<", "«", "„"].freeze

  # Characters as splittable suffixes with an optional matching prefix.
  PAIR_POST = [")", "}", "]", ">", "»", "“"].freeze

  # Characters which can be both prefixes AND suffixes.
  PRE_N_POST = ['"', "'"].freeze

  SPLITTABLES =
    (SIMPLE_PRE + SIMPLE_POST + PAIR_PRE + PAIR_POST + PRE_N_POST + ["\s"]).freeze
  PATTERN = Regexp.new("[#{Regexp.escape(SPLITTABLES.join)}]+").freeze

  # Reduced set for more common occurrences.
  # Strange city names as of 2021-02-12 (not counting aliases):
  # - 18 with comma ,
  # - 174 with period .
  # - 455 with parenthesis ( )
  # - 33 with brackets [ ]
  # - 662 with single quote '
  # - 1 with double quote
  # - 6233 with dash -
  # - 46 with dash surrounded by spaces " - "
  REDUCED_SPLITTABLES = (SPLITTABLES - ["'", "(", ")", "."]).freeze
  REDUCED_PATTERN = Regexp.new("[#{Regexp.escape(REDUCED_SPLITTABLES.join)}]+").freeze

  # For the same-named city such as Valencia in Spain and Valencia in Venezuela we create a
  # hardcoded list of all names that are definitely associated with a particular location.
  # The exact string as seen in LinkedIn profile is paired with a geoname ID in geonames.org.
  # rubocop:disable Style/NumericLiterals
  HARDCODED_LINKEDIN_NAMES = {
    "Greater Valencia Metropolitan Area" => 2509954
  }.freeze
  # rubocop:enable Style/NumericLiterals

  attr_reader :city, :country

  def initialize(str)
    @raw_string = str
  end

  # When city's country and parsed country are different - parsed country takes precedence.
  def parse(with_country: nil)
    return unless raw_string_valid?

    if (geoname_id = HARDCODED_LINKEDIN_NAMES[@raw_string]).present?
      hardcoded_location = Location.find_by!(geoname_id:)
      if hardcoded_location.city?
        @city = hardcoded_location
        @country = hardcoded_location.country
      elsif hardcoded_location.country?
        @city = nil
        @country = hardcoded_location
      else
        raise ArgumentError, "Hardcoded list of names does not match to a city or a country " \
                             "with '#{@raw_string}'"
      end
      return
    end

    possible_names = possible_names_from_raw_string.sort_by { |name| - name.split.size }
    if possible_names.size > 250
      @raw_string.tr!("0-9", "")
      possible_names = possible_names_from_raw_string.sort_by { |name| - name.split.size }

      if possible_names.size > 250
        ATS::Logger
          .new(where: "LocationParser#parse")
          .external_log(
            "Location raw_string has too many possible names",
            extra: {
              raw_string: @raw_string,
              possible_names_size: possible_names.size
            }
          )
        return
      end
    end

    matches_possible_names_query = <<~SQL
      EXISTS (
        SELECT 1
        FROM location_aliases la
        WHERE locations.id = la.location_id
        AND la.alias IN (?)
        LIMIT 1
      )
    SQL

    grouped_possible_locations =
      Location
      .where(matches_possible_names_query, possible_names)
      .includes(:location_aliases)
      .order(population: :desc)
      .group_by(&:type)
    return false if grouped_possible_locations["country"]&.size&.> 1

    @country = with_country || grouped_possible_locations["country"]&.first

    if @country.present?
      grouped_possible_locations.each do |key, group|
        grouped_possible_locations[key] = group.filter do |location|
          location.country_name == @country.name
        end
      end
    end

    possible_cities = grouped_possible_locations["city"] || []
    possible_admin_regions2 = grouped_possible_locations["admin_region2"] || []
    possible_admin_regions1 = grouped_possible_locations["admin_region1"] || []
    possible_cities_name_aliases =
      possible_cities.map { |city| city.location_aliases.map(&:alias) }.flatten

    exact_matched_city = nil
    possible_names.each do |name|
      next if possible_cities_name_aliases.exclude?(name)

      exact_matched_city =
        possible_cities.find do |city|
          city.location_aliases.map(&:alias).include?(name)
        end
      break
    end

    if !exact_matched_city && (possible_admin_regions2.any? || possible_admin_regions1.any?)
      cities_with_parents = {}
      region_types = %w[admin_region1 admin_region2]
      possible_cities.first(3).each do |possible_city|
        cities_with_parents[possible_city] =
          possible_city
          .parents
          .filter { |location| region_types.include?(location.type) }
          .group_by(&:type)
      end

      matched_by_parents_city = nil
      cities_with_parents.each do |possible_city, parents|
        if !parents["admin_region1"].intersect?(possible_admin_regions1) &&
           !parents["admin_region2"].intersect?(possible_admin_regions2)
          next
        end

        matched_by_parents_city = possible_city
        break
      end
    end

    @city = exact_matched_city || matched_by_parents_city || possible_cities.first

    @admin_region1 = possible_admin_regions1.first if @city.blank?
    @admin_region2 = possible_admin_regions2.first if @city.blank? && @admin_region1.blank?

    @country = city_or_any_region.country if @country.blank? && city_or_any_region.present?
    (@country.present? && with_country.nil?) || city_or_any_region.present?
  end

  def tokenize(str, regex: PATTERN)
    str.strip.split(regex).compact_blank
  end

  # Construct all consequent sequences of any size in order.
  def combinations(arr)
    result = arr.dup
    (2..arr.size).each do |window_size|
      arr.each_cons(window_size) do |a|
        result << a
      end
    end
    result
  end

  def raw_string_valid?
    @raw_string.present? &&
      !@raw_string.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))
  end

  def city_or_country
    @city || @country
  end

  private

  def possible_names_from_raw_string
    tokens = tokenize(@raw_string).filter { |tk| SPLITTABLES.exclude?(tk) }
    possible_names = combinations(tokens)
    tokens_reduced = tokenize(@raw_string, regex: REDUCED_PATTERN).filter do |tk|
      REDUCED_SPLITTABLES.exclude?(tk)
    end
    combinations(tokens_reduced).each { |c| possible_names << c }
    possible_names.uniq!
    possible_names.map! do |element|
      if element.is_a?(Array)
        element.join(" ")
      else
        element
      end
    end

    possible_names.grep_v(/^[[:alnum:]]$/)
  end

  def city_or_any_region
    @city || @admin_region2 || @admin_region1
  end
end
