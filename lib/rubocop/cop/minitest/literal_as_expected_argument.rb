# frozen_string_literal: true

# Enforces correct order of actual and
# expected arguments for `assert_equal`.
#
# From Toughbyte Test guide:
#   Prefer to place the actual value on the left and the expected value on the right,
#   the reverse of the default Minitest setting.
# Source: https://app.clickup.com/4567279/docs/4bc7f-1845/4bc7f-40225
#
# @example
#   # good
#   assert_equal foo, 2
#   assert_equal foo, [1, 2]
#   assert_equal foo, [1, 2], 'message'
#   assert_equal some_value, "some value"
#
#   # bad
#   assert_equal "some value", some_value
#   assert_equal 2, foo
#   assert_equal [1, 2], foo
#   assert_equal [1, 2], foo, 'message'
#
class RuboCop::Cop::Minitest::LiteralAsExpectedArgument < RuboCop::Cop::Base
  include RuboCop::Cop::ArgumentRangeHelper
  extend RuboCop::Cop::AutoCorrector

  MSG = "Replace the literal with the second argument."
  RESTRICT_ON_SEND = %i[assert_equal].freeze

  def on_send(node)
    return unless node.method?(:assert_equal)

    first, second, message = *node.arguments
    return unless first&.recursive_basic_literal?
    return if second.recursive_basic_literal?

    add_offense(all_arguments_range(node)) do |corrector|
      autocorrect(corrector, node, second, first, message)
    end
  end

  def autocorrect(corrector, node, second, first, message)
    arguments = [second.source, first.source, message&.source].compact.join(", ")
    corrector.replace(node, "assert_equal #{arguments}")
  end
end
