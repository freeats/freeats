# frozen_string_literal: true

class AuthorizedController < ApplicationController
  set_current_tenant_through_filter

  before_action :authenticate
  before_action :set_tenant
  before_action :set_navbar_variables,
                unless: -> {
                          request.format.json? || request.format.js? ||
                            request.format.turbo_stream?
                        }
  rescue_from ActionPolicy::Unauthorized, with: :user_not_authorized

  private

  def user_not_authorized
    respond_to do |format|
      format.html do
        redirect_back fallback_location: root_url,
                      alert: t("errors.forbidden_action")
      end
      format.json do
        render_error t("errors.forbidden_action"), status: :forbidden
      end
      format.turbo_stream do
        render_error t("errors.forbidden_action"), status: :forbidden
      end
    end
  end

  def set_tenant
    current_tenant = current_account&.tenant
    set_current_tenant(current_tenant)
  end

  def set_navbar_variables
    @pending_tasks_count = current_member.tasks_count if current_member
  end

  def authenticate
    rodauth.require_account # redirect to login page if not authenticated

    return if current_member.active?

    rodauth.forget_login
    rodauth.logout
    flash[:alert] = "This account has been deactivated."
    redirect_to rodauth.login_path
  end
end
