# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# rubocop:disable Style/ClassAndModuleChildren
module ATS
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults(7.1)

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.active_record.schema_format = :sql

    config.after_initialize do
      Rails.error.subscribe(ErrorSubscriber.new)
    end

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Permitted locales available for the application.
    config.i18n.available_locales = %i[en de]
    config.i18n.default_locale = :en

    config.view_component.default_preview_layout = "component_preview"
    config.eager_load_paths << Rails.root.join("test/components/previews")

    config.to_prepare do
      ActiveStorage::Attached::Changes::CreateOne.prepend(ActiveStorageCreateOne)
      ActiveStorage::Blob.singleton_class.prepend(ActiveStorageBlob)
      ActiveSupport.on_load(:active_storage_attachment) { include ActiveStorageAttachment }
    end

    MissionControl::Jobs.base_controller_class = "DevopsAuthenticationController"
  end
end
# rubocop:enable Style/ClassAndModuleChildren
