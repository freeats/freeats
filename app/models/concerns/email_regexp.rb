# frozen_string_literal: true

module EmailRegexp
  extend ActiveSupport::Concern

  EMAIL_REGEXP = %r{\A(?:[\w!#$%&*+\-\/=?^'`{|}~]+\.?)+(?<!\.)@(?:[a-z\d-]+\.)+[a-z]+\z}
  # No working method found that transfertes EMAIL_REGEXP into a pattern
  # for html. In some browsers specifying  `type: :email` solves some of
  # the frontend email validation issues, but this is not supported everywhere.
  HTML_EMAIL_PATTERN = '[^@\s]+@[^@\s]+'
end
