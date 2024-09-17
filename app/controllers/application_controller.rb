# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ErrorHandler

  set_current_tenant_through_filter

  before_action :check_gmail_blank_tokens
  before_action :set_selector_id_for_page
  before_action :set_tenant
  rescue_from ActionPolicy::Unauthorized, with: :user_not_authorized

  add_flash_types :warning

  around_action :switch_locale

  authorize :member, through: :current_member

  private

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

  def user_not_authorized
    respond_to do |format|
      format.html do
        unless current_member&.active?
          redirect_to login_url
          return
        end

        redirect_back fallback_location: root_url,
                      alert: "You are not allowed to perform this action."
      end
      format.json do
        render_error "You are not allowed to perform this action.", status: :forbidden
      end
      format.turbo_stream do
        render_error "You are not allowed to perform this action.", status: :forbidden
      end
    end
  end

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

  def set_tenant
    current_tenant = current_account&.tenant
    set_current_tenant(current_tenant)
  end

  helper_method :current_account, :current_member, :current_user

  def check_gmail_blank_tokens
    return if params[:controller]&.include?(mission_control_jobs_path)
    return if current_member.blank?
    return unless allowed_to?(:link_gmail?, with: ATS::ProfilePolicy)
    return if current_member.email_service_linked?

    address = current_member.email_address

    @email_blank_tokens_alert =
      %(Email #{address} is not linked. Please press <i>Link Gmail</i> button in
        <a href="#{ats_profile_url}">your profile</a> to synchronize emails.)
  end

  def set_selector_id_for_page
    controller = params[:controller] #=> "ats/candidates"
    return unless controller

    action = params[:action] #=> "show"
    @page_id = "#{controller.tr('/', '-')}-#{action}".dasherize #=> "ats-candidates-show"
  end

  def switch_locale(&)
    # TODO: use organization's locale for signed in users.
    locale = params[:locale]
    locale = I18n.default_locale unless locale&.to_sym&.in?(I18n.available_locales)
    I18n.with_locale(locale, &)
  end

  # Should add locale to each url if it's explicitly passed on the first request or is not default.
  def default_url_options
    locale = params[:locale] if params[:locale]&.to_sym&.in?(I18n.available_locales)
    locale ||= I18n.locale if I18n.locale != I18n.default_locale
    return {} if locale.blank?

    { locale: }
  end
end
