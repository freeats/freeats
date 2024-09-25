# frozen_string_literal: true

module EmailRegexp
  extend ActiveSupport::Concern

  EMAIL_REGEXP = %r{\A(?:[\w!#$%&*+\-\/=?^'`{|}~]+\.?)+(?<!\.)@(?:[a-z\d-]+\.)+[a-z]+\z}
end
