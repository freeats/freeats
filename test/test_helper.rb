# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# rubocop:disable Style/ClassAndModuleChildren
module ActiveSupport
  class TestCase
    parallelize if ENV["CI"].blank? # Disable parallelization for continuous integration.

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
# rubocop:enable Style/ClassAndModuleChildren
