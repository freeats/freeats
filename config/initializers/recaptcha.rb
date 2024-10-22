# frozen_string_literal: true

Recaptcha.configure do |config|
  config.site_key = ENV.fetch("RECAPTCHA_V2_SITE_KEY", nil)
  config.secret_key = ENV.fetch("RECAPTCHA_V2_SECRET_KEY", nil)
end

module Recaptcha
  ENABLED = configuration.site_key.present? && configuration.secret_key.present?
end
