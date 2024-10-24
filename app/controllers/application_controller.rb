# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ErrorHandler

  before_action :set_sentry_account_context
  before_action :set_sentry_context
  before_action :set_selector_id_for_page

  authorize :member, through: :current_member

  add_flash_types :warning

  private

  def current_account
    rodauth.rails_account
  end

  def current_member
    @current_member ||= current_account&.member
  end

  # Dummy method for action_policy, shouldn't be used anywhere.
  def current_user
    current_account
  end

  helper_method :current_account, :current_member, :current_user

  def set_selector_id_for_page
    controller = params[:controller] #=> "ats/candidates"
    return unless controller

    action = params[:action] #=> "show"
    @page_id = "#{controller.tr('/', '-')}-#{action}".dasherize #=> "ats-candidates-show"
  end

  def render_turbo_stream(streams, notice: nil, warning: nil, error: nil, alerts: [], status: :ok)
    stream_array = Array(streams).compact
    alert =
      if error.present? then { text: error, type: :error }
      elsif warning.present? then { text: warning, type: :warning }
      elsif notice.present? then { text: notice, type: :notice }
      end
    alerts << alert if alert
    # If alerts have been passed, we render them,
    # else an empty turbo stream that removes all alerts from the page.
    stream_array.push(
      if alerts.present?
        turbo_stream.replace("alerts", partial: "layouts/ats/alert", locals: { alerts: })
      else
        turbo_stream.update("alerts", "")
      end
    )
    render turbo_stream: stream_array, status:
  end

  def set_gon_variables
    default_value_in_megabytes = Rails.env.production? ? 0 : 5

    gon.nginx_file_size_limit_in_mega_bytes =
      ENV.fetch("NGINX_FILE_SIZE_LIMIT_IN_MEGA_BYTES", default_value_in_megabytes)
    gon.recaptcha_v3_site_key = RecaptchaV3::SITE_KEY if RecaptchaV3::ENABLED
  end

  def set_sentry_account_context
    return unless Rails.env.in?(Sentry.configuration.enabled_environments)

    if current_account
      Sentry.set_user(
        id: current_account.id,
        username: current_account.name,
        email: current_account.email,
        ip_address: "{{auto}}"
      )
    else
      Sentry.set_user(ip_address: "{{auto}}")
    end
  end

  def set_sentry_context
    return unless Rails.env.in?(Sentry.configuration.enabled_environments)

    Sentry.set_extras(params: params.to_unsafe_h, url: request.url)
  end
end
