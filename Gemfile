# frozen_string_literal: true

source "https://rubygems.org"

ruby file: ".ruby-version"

gem "action_policy"
gem "active_record_union"
# TODO: remove version restriction after fixing URL validation in the gem
# https://github.com/sporkmonger/addressable/issues/511
gem "addressable", "2.8.1"
gem "aws-sdk-s3", require: false
gem "blazer"
gem "bootsnap", require: false
gem "cocoon"
gem "cssbundling-rails"
gem "datagrid"
gem "dry-initializer"
gem "dry-logger"
gem "dry-monads"
gem "dry-schema"
gem "faraday"
gem "gon"
gem "googleauth"
gem "hashie"
gem "image_processing"
gem "inline_svg"
gem "jbuilder"
gem "jsbundling-rails"
gem "kaminari"
gem "liquid", "~> 5.0"
gem "lookbook", "~> 2.0.0"
gem "mission_control-jobs"
gem "omniauth-google-oauth2"
gem "pg", "~> 1.1"
gem "pghero"
gem "phonelib"
gem "puma", ">= 5.0"
gem "rails", "~> 7.1.0"
gem "rails_admin", "~> 3.0"
gem "rinku"
gem "rodauth-model"
gem "rodauth-omniauth"
gem "rodauth-rails"
gem "sassc-rails"
gem "signet"
gem "slim-rails"
gem "solid_queue"
gem "sprockets-rails"
gem "stimulus-rails"
gem "strip_attributes"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "view_component", "~> 3.0"

group :production, :development, :staging do
  gem "signet"
end

group :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "debug", platforms: %i[mri windows]
  gem "pry-byebug"
  gem "pry-inline"
  gem "pry-rails"
  gem "rubocop", require: false
  gem "rubocop-minitest", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "slim_lint", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  gem "dockerfile-rails", ">= 1.6"
  gem "dotenv-rails"
  gem "rack-mini-profiler"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "factory_bot_rails"
  gem "faker"
  gem "minitest-stub-const"
  gem "selenium-webdriver"
  gem "webmock"
end

# rubocop:disable Bundler/DuplicatedGem
group :staging do
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "debug", platforms: %i[mri windows]
  gem "dotenv-rails"
end
# rubocop:enable Bundler/DuplicatedGem
