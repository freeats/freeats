# frozen_string_literal: true

require "test_helper"

class SlimLintTest < ActiveSupport::TestCase
  test "check all files with slim-lint" do
    next if ENV["CI"].present?

    modified = `git diff --name-only origin/master '*.slim'`
    untracked = `git ls-files --others --exclude-standard  '*.slim'`
    deleted = `git diff --diff-filter D --name-only origin/master '*.slim'`
    excluded = Dir.glob("vendor/**/*") + Dir.glob("node_modules/**/*") + deleted.split("\n")
    files = (modified.split("\n") + untracked.split("\n") - excluded).join(" ")
    report = files.blank? ? "" : `slim-lint #{files}`

    assert_empty(report)
  end
end
