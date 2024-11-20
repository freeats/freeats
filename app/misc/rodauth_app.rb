# frozen_string_literal: true

# rubocop:disable Style/MethodCallWithArgsParentheses
class RodauthApp < Rodauth::Rails::App
  configure RodauthMain

  route do |r|
    rodauth.load_memory # autologin remembered users

    # Ignore "remember" plugin's routes since we don't need them right now.
    r.is "remember" do
      false
    end

    r.rodauth # route rodauth requests
  end
end
# rubocop:enable Style/MethodCallWithArgsParentheses
