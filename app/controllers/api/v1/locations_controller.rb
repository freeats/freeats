# frozen_string_literal: true

# Does not belong to a specific model, provides API for manipulating cities and countries
class API::V1::LocationsController < AuthorizedController
  before_action :authorize!
  before_action :check_minimum_query_length

  ALLOWED_LOCATION_TYPES = %w[city country].freeze

  def fetch_locations
    types =
      if params[:types].present?
        params[:types].split(",")
      else
        raise ArgumentError, "`types` parameter is required as location types divided by comma."
      end
    if (types - ALLOWED_LOCATION_TYPES).present?
      raise ArgumentError,
            "Only #{ALLOWED_LOCATION_TYPES.to_sentence(last_word_connector: ' and ')} " \
            "types are allowed."
    end

    locations = Location.search_by_name(params[:q], types:)

    ordered_locations = Locations::Order.new(locations:, query: params[:q]).call.value!
    json = ordered_locations.map do |location|
      {
        value: location.id,
        text: location.short_name
      }
    end

    render json:
  end

  private

  # Trgm gin index in Postgres requires at least 3 letters in the search to be present,
  # otherwise the index is not used and query can be potentially very time consuming.
  def check_minimum_query_length
    render json: [] if params[:q].blank? || params[:q].size < 3
  end
end
