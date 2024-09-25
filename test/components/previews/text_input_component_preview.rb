# frozen_string_literal: true

class TextInputComponentPreview < ViewComponent::Preview
  # @!group Variants
  # @param size select { choices: [tiny, small, medium] }
  # @param value text
  # @param placeholder text
  # @param subscript text
  # rubocop:disable Lint/UnusedMethodArgument
  def default(size: :medium, value: "Input", placeholder: "Input", subscript: "Form-text")
    placeholder ||= ""
    subscript ||= ""
    render(TextInputComponent.new("name", size:, placeholder:)) do |c|
      c.with_subscript(subscript)
    end
  end

  def filled(size: :medium, value: "Input", placeholder: "Input", subscript: "Form-text")
    placeholder ||= ""
    subscript ||= ""
    render(TextInputComponent.new("name", size:, value:, placeholder:)) do |c|
      c.with_subscript(subscript)
    end
  end

  def disabled(
    size: :medium,
    value: "Input",
    placeholder: "Input",
    subscript: "Form-text"
  )
    placeholder ||= ""
    subscript ||= ""
    render(TextInputComponent.new("name", size:, placeholder:, disabled: true)) do |c|
      c.with_subscript(subscript)
    end
  end

  def readonly(
    size: :medium,
    value: "Input",
    placeholder: "Input",
    subscript: "Form-text"
  )
    placeholder ||= ""
    subscript ||= ""
    render(TextInputComponent.new("name", size:, value:, placeholder:, readonly: true)) do |c|
      c.with_subscript(subscript)
    end
  end
  # rubocop:enable Lint/UnusedMethodArgument
  # @!endgroup
end
