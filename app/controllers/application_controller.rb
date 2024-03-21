# frozen_string_literal: true

class ApplicationController < ActionController::Base
  add_flash_types :warning

  private

  def current_account
    rodauth.rails_account
  end
  helper_method :current_account
end
