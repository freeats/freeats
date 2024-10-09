# frozen_string_literal: true

module RecaptchaV3
  MIN_SCORE = 0.5
  SITE_KEY = Rails.application.credentials.recaptcha_v3.site_key!
  SECRET_KEY = Rails.application.credentials.recaptcha_v3.secret_key!
end
