# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", :local)

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  config.active_job.queue_adapter = :solid_queue

  config.hosts = nil
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
  # Emails are saved to tmp/mails by default. Change to :smtp and add environment variables for
  # user_name and password to test as it works in production.
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
  config.action_mailer.smtp_settings = {
    user_name: ENV.fetch("MAILER_SMTP_USER_NAME", ""),
    password: ENV.fetch("MAILER_SMTP_PASSWORD", ""),
    address: ENV.fetch("MAILER_SMTP_ADDRESS", ""),
    port: ENV.fetch("MAILER_SMTP_PORT", "").to_i,
    domain: ENV.fetch("MAILER_SMTP_DOMAIN", ""),
    authentication: ENV.fetch("MAILER_SMTP_AUTHENTICATION", ""),
    enable_starttls_auto: ENV.fetch("MAILER_SMTP_ENABLE_STARTTLS_AUTO", "true") == "true"
  }
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE")

  ENV["HOST_URL"] = "localhost:3000"
  ENV["EMAIL_NOTIFICATIONS"] = "enabled"
end
