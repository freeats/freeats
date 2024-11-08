# frozen_string_literal: true

# rubocop:disable Style/MethodCallWithArgsParentheses, Rails
class RodauthApp < Rodauth::Rails::App
  configure RodauthMain

  route do |r|
    # Ignore configuration for custom actions.
    return if r.path.in?(["/invitation", "/accept_invite", "/recaptcha/verify"])

    # Ignore configuration for custom actions which used basic authentication.
    routes = Rails.application.routes.url_helpers
    basic_auth_routes = [
      routes.rails_admin_path,
      routes.pg_hero_path,
      routes.mission_control_jobs_path
    ]

    return if basic_auth_routes.any? { r.path.start_with?(_1) }

    rodauth.load_memory # autologin remembered users

    # Ignore configuration for career site. We don't need to authenticate.
    return if r.path.start_with?("/sites/")

    # Ignore "remember" plugin's routes since we don't need them right now.
    r.is "remember" do
      false
    end

    r.rodauth # route rodauth requests

    rodauth.require_account

    unless rodauth.active?
      rodauth.forget_login
      rodauth.logout
      flash[:alert] = "This account has been deactivated."
      r.redirect "/sign_in"
    end
  end
end
# rubocop:enable Style/MethodCallWithArgsParentheses, Rails
