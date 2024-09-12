# frozen_string_literal: true

class ErrorSubscriber
  def report(error, handled:, severity:, context:, source: nil)
    return if handled

    ATS::Logger
      .new(where: source)
      .external_log(
        error,
        extra: {
          context:,
          severity:
        }
      )
  end
end
