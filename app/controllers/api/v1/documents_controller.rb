# frozen_string_literal: true

class API::V1::DocumentsController < ApplicationController
  include Dry::Monads[:result]
  skip_before_action :verify_authenticity_token
  around_action :handle_error

  def create
    url = AccountLink.new(params[:url]).normalize
    params_hash = prepare_params(params)
    file = params_hash.delete(:cv)
    file.original_filename = "resume.pdf"

    ActiveRecord::Base.transaction do
      case create_or_update_candidate(params_hash, url)
      in Success(candidate)
        case add_resume(candidate, file)
        in Success(file)
          render json: { url: candidate.url }, status: :ok
        in Failure[:validation_failed, e]
          render json: { message: error_message(e) }, status: :unprocessable_entity
        end
      in Failure[:candidate_invalid, e]
        render json: { message: error_message(e) }, status: :unprocessable_entity
      end
    end
  end

  private

  def prepare_params(params)
    result = params.permit(:url, :full_name, :location, :headline, :avatar, :cv).to_h
    lp = LocationParser.new(result.delete(:location))
    result[:location_id] = lp.city_or_country.id.to_s if lp.parse
    result[:links] = [{ url: result.delete(:url), status: "current" }]
    result.deep_symbolize_keys
  end

  def create_or_update_candidate(params, url)
    if (duplicate = find_mergeable_duplicate(url)).present?
      Candidates::Change.new(candidate: duplicate, params:, actor_account: current_account).call
    else
      Candidates::Add.new(params:, actor_account: current_account).call
    end
  end

  def add_resume(candidate, file)
    Candidates::UploadFile.new(
      candidate:,
      actor_account: current_account,
      file:,
      cv: true
    ).call
  end

  def find_mergeable_duplicate(url)
    Candidate
      .not_merged
      .duplicates_by_emails_links_and_phones(
        emails: [],
        phones: [],
        links: [url]
      )
      .order("last_activity_at DESC NULLS LAST")
      .first
  end

  def error_message(error)
    "ATS Error\n#{error}\nPlease contact support."
  end

  def handle_error
    yield
  rescue StandardError => e
    render json: { message: error_message(e) }, status: :internal_server_error
  end
end
