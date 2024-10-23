# frozen_string_literal: true

class DevopsAuthenticationController < ActionController::Base # rubocop:disable Rails/ApplicationController
  include ErrorHandler

  http_basic_authenticate_with(
    name: ENV.fetch("SUPERUSER_NAME", "devops"),
    password: ENV.fetch("SUPERUSER_PASSWORD", SecureRandom.alphanumeric(10))
  )
end
