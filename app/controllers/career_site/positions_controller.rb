# frozen_string_literal: true

class CareerSite::PositionsController < ApplicationController
  include Dry::Monads[:result]
  set_current_tenant_through_filter

  layout "career_site/application"

  before_action :set_cors_headers
  before_action :set_gon_variables
  before_action :set_locale
  protect_from_forgery with: :null_session, prepend: true

  def index
    if current_tenant.nil? || !current_tenant.career_site_enabled
      render404
      return
    end

    if current_tenant.slug != params[:tenant_slug]
      redirect_to career_site_positions_path(tenant_slug: current_tenant.slug, locale: @locale)
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
          redirect_to career_site_position_path(
            tenant_slug: current_tenant.slug, id: @position.slug, locale: @locale
          ), status: :moved_permanently
          return
        end
      end
      # Otherwise render 404 error.
      render404
      return
    end

    if params[:id] != @position.slug || current_tenant.slug != params[:tenant_slug]
      redirect_to career_site_position_path(
        tenant_slug: current_tenant.slug, id: @position.slug, locale: @locale
      ), status: :moved_permanently
      return
    end

    @custom_styles = process_scss(current_tenant.public_styles)
  end

  def apply
    if current_tenant.nil? || !current_tenant.career_site_enabled
      render404
      return
    end

    set_current_tenant(current_tenant)

    position = Position.where.not(status: :draft).find(params[:position_id])

    recaptcha_v2_modal_was_shown = !params["g-recaptcha-response"].nil?

    recaptcha_v3_passed =
      RecaptchaV3::ENABLED &&
      !recaptcha_v2_modal_was_shown &&
      helpers.public_recaptcha_v3_verified?(
        recaptcha_v3_score: params[:recaptcha_v3_score]
      )

    unless recaptcha_v3_passed
      if Recaptcha::ENABLED && !recaptcha_v2_modal_was_shown
        render turbo_stream: turbo_stream.update(:turbo_recaptcha,
                                                 partial: "public/recaptcha_modal")
        return
      end

      if RecaptchaV3::ENABLED && !Recaptcha::ENABLED
        render_error t("recaptcha.error"), status: :unprocessable_entity
        return
      end
    end

    if recaptcha_v2_modal_was_shown && !helpers.public_recaptcha_v2_verified?(
      recaptcha_v2_response: params["g-recaptcha-response"]
    )
      render_error t("recaptcha.error"), status: :unprocessable_entity
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
      redirect_to career_site_position_path(
        tenant_slug: current_tenant.slug, id: position.slug, locale: @locale
      ), notice: t("career_site.positions.successfully_applied",
                   position_name: position.name)
    in Failure[:candidate_invalid, candidate_or_message]
      error_message =
        if candidate_or_message.is_a?(Candidate)
          candidate_or_message&.errors&.full_messages
        else
          candidate_or_message
        end
      render_error error_message, status: :unprocessable_entity
    in Failure[:placement_invalid, _e] | Failure[:task_invalid, _e] | # rubocop:disable Lint/UnderscorePrefixedVariableName
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
      Tenant.friendly.find(params[:tenant_slug])
  end

  def set_cors_headers
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS, HEAD"
    response.headers["Access-Control-Allow-Headers"] =
      "Origin, Content-Type, Accept"
    response.headers["Access-Control-Expose-Headers"] = "X-CSRF-Token"
    response.headers["Content-Security-Policy"] = "frame-ancestors *"
  end

  def set_locale
    locale = params[:locale]
    if locale && I18n.available_locales.include?(locale.to_sym)
      I18n.locale = locale
      @locale = locale
    elsif locale.present?
      I18n.locale = I18n.default_locale
      flash[:alert] = I18n.t("errors.locale_not_available", language: locale)
    else
      I18n.locale = I18n.default_locale
    end
  end
end
