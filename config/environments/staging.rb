# frozen_string_literal: true

require File.expand_path("production.rb", __dir__)

Rails.application.configure do
  # Here override any defaults
  # config.serve_static_files = true

  config.force_ssl = false
  config.assume_ssl = false
  config.action_mailer.smtp_settings = {
    user_name: Rails.application.credentials.sendgrid.username!,
    password: Rails.application.credentials.sendgrid.password!,
    address: "smtp.sendgrid.net",
    port: 587,
    domain: Rails.application.credentials.sendgrid.domain!,
    authentication: "plain",
    enable_starttls_auto: true
  }
end
