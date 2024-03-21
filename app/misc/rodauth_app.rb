# frozen_string_literal: true

class RodauthApp < Rodauth::Rails::App
  # primary configuration
  configure RodauthMain

  # secondary configuration
  # configure RodauthAdmin, :admin

  route do |r|
    rodauth.load_memory # autologin remembered users

    # Automatic authentication in development.
    if Rails.env.development?
      auth_email = ENV.fetch("AUTH_EMAIL", "admin@mail.com")
      if ENV["AUTH_NOLOGIN"].present? && rodauth.authenticated?
        rodauth.forget_login
        rodauth.logout
      elsif ENV["AUTH_NOLOGIN"].blank? && !rodauth.authenticated?
        rodauth.account_from_login(auth_email)
        rodauth.login("password")
      elsif ENV["AUTH_NOLOGIN"].blank? && rodauth.authenticated?
        rodauth.account_from_session
        if rodauth.account[:email] != auth_email
          rodauth.logout
          rodauth.account_from_login(auth_email)
          rodauth.login("password")
        end
      end
    end

    r.rodauth # route rodauth requests

    # ==> Authenticating requests
    # Call `rodauth.require_account` for requests that you want to
    # require authentication for. For example:
    #
    # # authenticate /dashboard/* and /account/* requests
    # if r.path.start_with?("/dashboard") || r.path.start_with?("/account")
    #   rodauth.require_account
    # end

    # ==> Secondary configurations
    # r.rodauth(:admin) # route admin rodauth requests
  end
end
