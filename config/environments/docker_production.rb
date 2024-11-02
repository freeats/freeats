# frozen_string_literal: true

require File.expand_path("production.rb", __dir__)

# Here override any defaults
Rails.application.configure do
  config.force_ssl = false
  config.assume_ssl = false

  # config.log_level = "debug"
end
