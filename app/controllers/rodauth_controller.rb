# frozen_string_literal: true

class RodauthController < ApplicationController
  layout "ats/application"
  # used by Rodauth for rendering views, CSRF protection, and running any
  # registered action callbacks and rescue_from handlers
end
