# frozen_string_literal: true

require "test_helper"

class RubocopTest < ActiveSupport::TestCase
  test "check all files with rubocop" do
    next if ENV["CI"].present?

    modified = `git diff --name-only origin/main '*.rb' '*.rake'`
    untracked = `git ls-files --others --exclude-standard --exclude='vendor/**/*' '*.rb' '*.rake'`
    excluded = %w[db/data_schema.rb] + Dir.glob("bin/*") +
               Dir.glob("vendor/**/*") + Dir.glob("node_modules/**/*")
    files = (modified.split("\n") + untracked.split("\n") - excluded).join(" ")
    report = files.blank? ? "" : `rubocop #{files}`

    assert_no_match(/Offenses:/, report, "Rubocop report:\n#{@report}")
  end
end
