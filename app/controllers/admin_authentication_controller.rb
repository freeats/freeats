# frozen_string_literal: true

class AdminAuthenticationController < ActionController::Base # rubocop:disable Rails/ApplicationController
  include ErrorHandler

  http_basic_authenticate_with name: Rails.application.credentials.dig(:superuser, :name),
                               password: Rails.application.credentials.dig(:superuser, :password)
end
