# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry.dsn!

  config.breadcrumbs_logger = [:active_support_logger]

  config.traces_sample_rate = 0.5

  # Scrape values: user ip, user cookie, request body.
  config.send_default_pii = true

  config.enabled_environments = %w[production]
end
