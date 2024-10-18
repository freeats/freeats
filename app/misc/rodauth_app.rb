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

    return if r.path.match?(%r{^/positions})

    # Authentication in testing.
    if Rails.env.test?
      r.on "test-environment-only" do
        r.is "please-login" do
          rodauth.account_from_login(r.params["email"])
          rodauth.login("omniauth")
        end
      end
    end

    # Ignore "remember" plugin's routes since we don't need them right now.
    r.is "remember" do
      false
    end

    r.rodauth # route rodauth requests

    r.get "auth", String, "callback" do
      return false if rodauth.omniauth_provider != "google_oauth2"

      omniauth_identities_ds = rodauth.db[:account_identities]
      accounts_ds = rodauth.db[:accounts]

      omniauth_identity = omniauth_identities_ds.first(
        provider: rodauth.omniauth_provider,
        uid: rodauth.omniauth_uid
      )

      if !rodauth.account && omniauth_identity
        rodauth.instance_variable_set(
          :@account,
          accounts_ds.first(id: omniauth_identity[:account_id])
        )
      end

      unless rodauth.account # rubocop:disable Style/IfUnlessModifier
        rodauth.account_from_login(rodauth.omniauth_email)
      end

      unless rodauth.account
        flash[:alert] = "An account with this email does not exist."
        r.redirect "/sign_in"
      end

      if rodauth.account && !rodauth.member
        omniauth_identities_ds.where(account_id: rodauth.account[:id]).delete
        flash[:alert] = "This account has no associated member."
        r.redirect "/sign_in"
      end

      if rodauth.account && !rodauth.active?
        omniauth_identities_ds.where(account_id: rodauth.account[:id]).delete
        flash[:alert] = "This account has been deactivated."
        r.redirect "/sign_in"
      end

      unless omniauth_identity
        identity_id = omniauth_identities_ds.insert(
          account_id: rodauth.account[:id],
          provider: rodauth.omniauth_provider.to_s,
          uid: rodauth.omniauth_uid
        )
        rodauth.instance_variable_set(:@omniauth_identity, { id: identity_id })
      end

      rodauth.login("omniauth")
    end

    rodauth.require_account

    unless rodauth.active?
      rodauth.db[:account_identities].where(account_id: rodauth.account[:id]).delete
      rodauth.forget_login
      rodauth.logout
      flash[:alert] = "This account has been deactivated."
      r.redirect "/sign_in"
    end
  end
end
# rubocop:enable Style/MethodCallWithArgsParentheses, Rails
