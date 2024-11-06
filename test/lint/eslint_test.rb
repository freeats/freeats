# frozen_string_literal: true

require "test_helper"

class EslintTest < ActiveSupport::TestCase
  test "check all files with eslint" do
    next if ENV["CI"].present?

    modified = `git diff --name-only origin/main '*.js'`
    untracked = `git ls-files --others --exclude-standard  '*.js'`
    deleted = `git diff --diff-filter D --name-only origin/main '*.js'`
    excluded = Dir.glob("bin/*") + Dir.glob("config/**/*") + Dir.glob("node_modules/**/*") + deleted.split("\n")
    files = (modified.split("\n") + untracked.split("\n") - excluded).join(" ")
    report = files.blank? ? "" : `node_modules/eslint/bin/eslint.js #{files}`

    assert_equal(report.length, 0, "Eslint report:\n#{@report}")
  end
end
