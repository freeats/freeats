# frozen_string_literal: true

class CareerSite::PositionsController < ApplicationController
  include Dry::Monads[:result]
  set_current_tenant_through_filter

  layout "career_site/application"

  before_action :set_cors_headers
  protect_from_forgery with: :null_session, prepend: true

  def index
    if current_tenant.nil? || !current_tenant.career_site_enabled
      render404
      return
    end
    set_current_tenant(current_tenant)

    @positions = Position.open
    @custom_styles = process_scss(current_tenant.public_styles)
  end

  def show
    if current_tenant.nil? || !current_tenant.career_site_enabled
      render404
      return
    end

    set_current_tenant(current_tenant)

    position_base_query =
      Position.where.not(status: :draft)
    begin
      @position = position_base_query.friendly.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      # If record was not found by slug, then look up ID at the end of the slug.
      # Try to find position by that ID.
      if (matches = params[:id].match(/-(\d+)$/))
        position_id = matches.captures.first
        @position = position_base_query.find_by(id: position_id)
        # If such position exists, redirect to proper route.
        if @position.present?
          redirect_to position_path(@position.slug), status: :moved_permanently
          return
        end
      end
      # Otherwise render 404 error.
      render404
      return
    end

    if params[:id] != @position.slug
      redirect_to position_path(@position.slug), status: :moved_permanently
      return
    end

    @company_name = current_tenant.name
    @custom_styles = process_scss(current_tenant.public_styles)
  end

  def apply
    if current_tenant.nil? || !current_tenant.career_site_enabled
      render404
      return
    end

    set_current_tenant(current_tenant)

    position = Position.where.not(status: :draft).find(params[:position_id])

    unless helpers.public_recaptcha_v3_verified?(
      recaptcha_v3_score: params[:recaptcha_v3_score],
      recaptcha_v2_response: params["g-recaptcha-response"]
    )
      render turbo_stream: turbo_stream.update(:turbo_recaptcha,
                                               partial: "public/application/recaptcha_modal")
      return
    end

    unless helpers.public_recaptcha_v2_verified?(
      recaptcha_v2_response: params["g-recaptcha-response"]
    )
      render_error I18n.t("career_site.recaptcha_error"), status: :unprocessable_entity
      return
    end

    candidate_params =
      {
        full_name: params[:full_name],
        email: params[:email],
        file: params[:file]
      }

    case Candidates::Apply.new(
      params: candidate_params,
      position_id: position.id,
      actor_account: nil
    ).call
    in Success
      redirect_to position_path(position.slug),
                  notice: t("career_site.positions.successfully_applied",
                            position_name: position.name)
    in Failure[:candidate_invalid, candidate_or_message]
      error_message =
        if candidate_or_message.is_a?(Candidate)
          candidate_or_message&.errors&.full_messages
        else
          candidate_or_message
        end
      render_error error_message, status: :unprocessable_entity
    in Failure[:placement_invalid, _e] | Failure[:task_invalid, _e] |
       Failure[:new_stage_invalid, _e] | Failure[:file_invalid, _e] |
       Failure[:event_invalid, _e] | Failure[:inactive_assignee, _e]
      ATS::Logger
        .new(where: "CareerSite::PositionsController#apply")
        .external_log(
          "Apply on a position failed",
          extra: {
            error_message: _e,
            position_id: position.id,
            candidate_params:
          }
        )
      render_error I18n.t("errors.something_went_wrong"), status: :unprocessable_entity
    end
  end

  private

  def process_scss(scss_content)
    engine = SassC::Engine.new(scss_content, syntax: :scss)
    engine.render
  end

  def current_tenant
    @current_tenant ||=
      Tenant.find_by(domain: request.host) ||
      Tenant.find_by(subdomain: request.subdomain.presence)
  end

  def set_cors_headers
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS, HEAD"
    response.headers["Access-Control-Allow-Headers"] =
      "Origin, Content-Type, Accept"
    response.headers["Access-Control-Expose-Headers"] = "X-CSRF-Token"
    response.headers["Content-Security-Policy"] = "frame-ancestors *"
  end
end
