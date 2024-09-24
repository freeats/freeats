# frozen_string_literal: true

# This exception is fired by `render_error` when it is a testing environment. This makes tests
# actively anticipate the error in an explicit way.
class RenderErrorExceptionForTests < StandardError; end
