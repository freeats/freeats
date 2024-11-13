# frozen_string_literal: true

source "https://rubygems.org"

ruby file: ".ruby-version"

gem "action_policy"
gem "active_record_union"
gem "acts_as_tenant"
gem "addressable"
gem "aws-sdk-s3", require: false
gem "blazer"
gem "bootsnap", require: false
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
gem "irb"
gem "jbuilder"
gem "jsbundling-rails"
gem "kaminari"
gem "lookbook", "~> 2.0.0"
gem "mission_control-jobs"
gem "pg", "~> 1.1"
gem "pghero"
gem "phonelib"
gem "puma", ">= 5.0"
gem "rails", "~> 7.1.0"
gem "rails_admin", "~> 3.1"
gem "recaptcha"
gem "rinku"
gem "rodauth-model"
gem "rodauth-rails"
gem "rubyzip"
gem "sassc-rails"
gem "sentry-rails"
gem "sentry-ruby"
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

group :staging, :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "debug", platforms: %i[mri windows]
end

group :staging, :development do
  gem "dotenv-rails"
end

group :development, :test do
  gem "faker"
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
  gem "dockerfile-rails", ">= 1.6"
  gem "letter_opener"
  gem "rack-mini-profiler"
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "factory_bot_rails"
  gem "minitest-stub-const"
  gem "selenium-webdriver"
  gem "webmock"
end

gem "friendly_id", "~> 5.5"
