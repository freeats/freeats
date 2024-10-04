# frozen_string_literal: true

class DevopsAuthenticationController < ActionController::Base # rubocop:disable Rails/ApplicationController
  include ErrorHandler

  http_basic_authenticate_with name: Rails.application.credentials.superuser.name!,
                               password: Rails.application.credentials.superuser.password!
end
