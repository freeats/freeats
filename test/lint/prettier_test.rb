# frozen_string_literal: true

require "test_helper"

class PrettierTest < ActiveSupport::TestCase
  test "check all files with prettier" do
    next if ENV["CI"].present?

    assert_empty `node_modules/prettier/bin/prettier.cjs -l .`
  end
end
