# frozen_string_literal: true

class ApplicationSchema < Dry::Schema::Params
  define do
    config.validate_keys = true
  end
end
