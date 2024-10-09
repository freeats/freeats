# frozen_string_literal: true

Recaptcha.configure do |config|
  config.site_key = Rails.application.credentials.recaptcha_v2.site_key!
  config.secret_key = Rails.application.credentials.recaptcha_v2.secret_key!
end
