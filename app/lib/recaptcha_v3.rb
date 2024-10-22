# frozen_string_literal: true

module RecaptchaV3
  MIN_SCORE = 0.5
  SITE_KEY = ENV.fetch("RECAPTCHA_V3_SITE_KEY", nil)
  SECRET_KEY = ENV.fetch("RECAPTCHA_V3_SECRET_KEY", nil)
  ENABLED = SITE_KEY.present? && SECRET_KEY.present?
end
