# frozen_string_literal: true

# rubocop:disable Style/MethodCallWithArgsParentheses, Rails
class RodauthApp < Rodauth::Rails::App
  configure RodauthMain, render: false

  route do |r|
    rodauth.load_memory # autologin remembered users

    # Automatic authentication in development.
    if Rails.env.development? && !ENV.fetch("AUTH_NOLOGIN", false)
      auth_email = ENV.fetch("AUTH_EMAIL", "admin@mail.com")
      if rodauth.authenticated?
        rodauth.account_from_session
        if rodauth.account[:email] != auth_email
          rodauth.logout
          rodauth.account_from_login(auth_email)
          rodauth.login("omniauth")
        end
      else
        rodauth.account_from_login(auth_email)
        rodauth.login("omniauth")
      end
    end

    # Authentication in testing.
    if Rails.env.test?
      r.on "test-environment-only" do
        r.is "please-login" do
          rodauth.account_from_login(r.params["email"])
          rodauth.login("omniauth")
        end
      end
    end

    # Authentication in staging.
    if Rails.env.staging?
      r.on "staging-environment-only" do
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
