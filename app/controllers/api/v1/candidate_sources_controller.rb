# frozen_string_literal: true

class API::V1::CandidateSourcesController < ApplicationController
  before_action :authorize!
  before_action :check_minimum_query_length

  ALLOWED_LOCATION_TYPES = %w[city country].freeze

  def fetch_candidate_sources
    dataset = CandidateSource.search_by_name(params[:q]).order(:name).limit(10)
    data = dataset.map do |candidate_source|
      helpers.candidates_compose_source_option_for_select(candidate_source, selected: false)
    end
    render json: data, status: :accepted
  end

  private

  # Trgm gin index in Postgres requires at least 3 letters in the search to be present,
  # otherwise the index is not used and query can be potentially very time consuming.
  def check_minimum_query_length
    render json: [] if params[:q].blank? || params[:q].size < 3
  end
end
