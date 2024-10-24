# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV.fetch("SENTRY_DSN", "dummy")

  config.breadcrumbs_logger = [:active_support_logger]

  config.traces_sample_rate = 0.5

  # Scrape values: user ip, user cookie, request body.
  config.send_default_pii = true
  # List all environments on which you would like to use Sentry ast comma-separated string, example:
  # SENTRY_ENABLED_ENVIRONMENTS="production,staging"
  config.enabled_environments = ENV.fetch("SENTRY_ENABLED_ENVIRONMENTS", "").split(",")
end
