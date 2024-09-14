# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "minitest/stub_const"

# rubocop:disable Style/ClassAndModuleChildren
module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Necessary to test ActiveStorage when we render files tab with the disk service,
    # otherwise we got an error when trying to compose url for the file.
    ActiveSupport.on_load(:action_controller) { include ActiveStorage::SetCurrent }

    Faraday.default_adapter = :test

    def sign_in(account)
      post("/test-environment-only/please-login", params: { email: account.email })
    end

    def sign_out
      post("/sign_out")
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
