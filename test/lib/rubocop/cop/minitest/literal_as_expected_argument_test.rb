# frozen_string_literal: true

require "test_helper"
require "rubocop-minitest"
require "rubocop/minitest/assert_offense"
require "./lib/rubocop/cop/minitest/literal_as_expected_argument"

class LiteralAsExpectedArgumentTest < ActiveSupport::TestCase
  include RuboCop::Minitest::AssertOffense

  setup do
    @cop = ::RuboCop::Cop::Minitest::LiteralAsExpectedArgument.new
  end

  test "should work if first argument is basic literal" do
    assert_offense(<<~RUBY)
      class FooTest < ActiveSupport::TestCase
        test "some test" do
          assert_equal "Test", test
                       ^^^^^^^^^^^^ Replace the literal with the second argument.
        end
      end
    RUBY

    assert_correction(<<~RUBY)
      class FooTest < ActiveSupport::TestCase
        test "some test" do
          assert_equal test, "Test"
        end
      end
    RUBY
  end

  test "should work if first argument is recursive basic literal" do
    assert_offense(<<~RUBY)
      class FooTest < ActiveSupport::TestCase
        test "some test" do
          assert_equal [1, 2, { key: :value }], foo
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Replace the literal with the second argument.
        end
      end
    RUBY

    assert_correction(<<~RUBY)
      class FooTest < ActiveSupport::TestCase
        test "some test" do
          assert_equal foo, [1, 2, { key: :value }]
        end
      end
    RUBY
  end

  test "should not register offense when second argument is not literal" do
    assert_no_offenses(<<~RUBY)
      class FooTest < ActiveSupport::TestCase
        test "some test" do
          assert_equal(foo, bar)
        end
      end
    RUBY
  end

  test "should not register offense when second argument is literal in parens" do
    assert_no_offenses(<<~RUBY)
      class FooTest < ActiveSupport::TestCase
        test "some test" do
          assert_equal(foo, 2)
        end
      end
    RUBY
  end

  test "should not register offense when second argument is literal without parents" do
    assert_no_offenses(<<~RUBY)
      class FooTest < ActiveSupport::TestCase
        test "some test" do
          assert_equal foo, 2
        end
      end
    RUBY
  end

  test "should not register offense when given_splat" do
    assert_no_offenses(<<~RUBY)
      class FooTest < ActiveSupport::TestCase
        test "some test" do
          assert_equal(*foo)
        end
      end
    RUBY
  end

  test "should not register offense when first and second argument are basic literal" do
    assert_no_offenses(<<~RUBY)
      class FooTest < ActiveSupport::TestCase
        test "some test" do
          assert_equal 0, 1, 'message'
        end
      end
    RUBY
  end
end
