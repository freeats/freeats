# frozen_string_literal: true

class ButtonComponentPreview < ViewComponent::Preview
  # @param content text
  # @param icon_name text
  # @param size select { choices: [tiny, small, medium] }
  # @param icon_type select { choices: [outline, filled] }
  # @param disabled toggle
  # @param icon_position select { choices: ["off", left, right] }
  #
  # @!group Variants
  def primary(
    icon_name: :arrow_right,
    size: :medium,
    disabled: false,
    icon_type: :outline,
    content: "Button",
    icon_position: :off
  )
    render(ButtonComponent.new(size:, disabled:)) do |c|
      with_icon(c, icon_name, icon_position, icon_type:, size:)
      content.to_s
    end
  end

  def secondary(
    icon_name: :arrow_right,
    size: :medium,
    disabled: false,
    icon_type: :outline,
    content: "Button",
    icon_position: :off
  )
    render(ButtonComponent.new(variant: :secondary, size:, disabled:)) do |c|
      with_icon(c, icon_name, icon_position, icon_type:, size:)
      content.to_s
    end
  end

  def cancel(
    icon_name: :arrow_right,
    size: :medium,
    disabled: false,
    icon_type: :outline,
    content: "Button",
    icon_position: :off
  )
    render(ButtonComponent.new(variant: :cancel, size:, disabled:)) do |c|
      with_icon(c, icon_name, icon_position, icon_type:, size:)
      content.to_s
    end
  end

  def danger(
    icon_name: :arrow_right,
    size: :medium,
    disabled: false,
    icon_type: :outline,
    content: "Button",
    icon_position: :off
  )
    render(ButtonComponent.new(variant: :danger, size:, disabled:)) do |c|
      with_icon(c, icon_name, icon_position, icon_type:, size:)
      content.to_s
    end
  end

  def danger_secondary(
    icon_name: :arrow_right,
    size: :medium,
    disabled: false,
    icon_type: :outline,
    content: "Button",
    icon_position: :off
  )
    render(ButtonComponent.new(variant: :danger_secondary, size:, disabled:)) do |c|
      with_icon(c, icon_name, icon_position, icon_type:, size:)
      content.to_s
    end
  end

  def with_tooltip(
    icon_name: :arrow_right,
    size: :medium,
    disabled: false,
    icon_type: :outline,
    content: "Button",
    icon_position: :off
  )
    render(ButtonComponent.new(size:, disabled:, tooltip_title: "Tooltip")) do |c|
      with_icon(c, icon_name, icon_position, icon_type:, size:)
      content.to_s
    end
  end

  def disabled_with_tooltip(
    icon_name: :arrow_right,
    size: :medium,
    disabled: false,
    icon_type: :outline,
    content: "Button",
    icon_position: :off
  )
    render(ButtonComponent.new(size:, disabled:, tooltip_title: "Tooltip")) do |c|
      with_icon(c, icon_name, icon_position, icon_type:, size:)
      content.to_s
    end
  end
  # @!endgroup

  private

  def with_icon(component, icon_name, position, icon_type:, size:)
    return if position == :off

    component.with_icon(icon_name, position:, icon_type:, size:)
  end
end
