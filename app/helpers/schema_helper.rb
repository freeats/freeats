# frozen_string_literal: true

module SchemaHelper
  def schema_errors_to_string(errors)
    return "" if errors.blank?

    errors.messages.map { |mes| schema_full_message(mes) }.join(", ")
  end

  def schema_full_message(message)
    "#{message.path.is_a?(Array) ? message.path.join(', ') : message.path.to_s}: #{message.text}"
  end
end
