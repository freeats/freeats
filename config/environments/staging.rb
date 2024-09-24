# frozen_string_literal: true

require File.expand_path("production.rb", __dir__)

Rails.application.configure do
  # Here override any defaults
  # config.serve_static_files = true

  config.force_ssl = false
  config.assume_ssl = false

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true
end
