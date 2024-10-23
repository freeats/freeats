# frozen_string_literal: true

class ButtonComponentPreview < ViewComponent::Preview
  # @param content text
  # @param size select { choices: [tiny, small, medium] }
  # @param disabled toggle
  # @param icon select { choices: ["off", left, right] }
  # @!group Variants
  def primary(size: :medium, disabled: false, content: "Button", icon: :off)
    render(ButtonComponent.new(size:, disabled:)) do |c|
      with_icon(c, icon)
      content.to_s
    end
  end

  def secondary(size: :medium, disabled: false, content: "Button", icon: :off)
    render(ButtonComponent.new(variant: :secondary, size:, disabled:)) do |c|
      with_icon(c, icon)
      content.to_s
    end
  end

  def cancel(size: :medium, disabled: false, content: "Button", icon: :off)
    render(ButtonComponent.new(variant: :cancel, size:, disabled:)) do |c|
      with_icon(c, icon)
      content.to_s
    end
  end

  def danger(size: :medium, disabled: false, content: "Button", icon: :off)
    render(ButtonComponent.new(variant: :danger, size:, disabled:)) do |c|
      with_icon(c, icon)
      content.to_s
    end
  end

  def danger_secondary(size: :medium, disabled: false, content: "Button", icon: :off)
    render(ButtonComponent.new(variant: :danger_secondary, size:, disabled:)) do |c|
      with_icon(c, icon)
      content.to_s
    end
  end

  def with_tooltip(size: :medium, disabled: false, content: "Button", icon: :off)
    render(ButtonComponent.new(size:, disabled:, tooltip_title: "Tooltip")) do |c|
      with_icon(c, icon)
      content.to_s
    end
  end

  def disabled_with_tooltip(size: :medium, disabled: true, content: "Button", icon: :off)
    render(ButtonComponent.new(size:, disabled:, tooltip_title: "Tooltip")) do |c|
      with_icon(c, icon)
      content.to_s
    end
  end
  # @!endgroup

  # TODO: remove after migrate all components to tabler
  # @param content text
  # @param tabler_icon_name text
  # @param size select { choices: [tiny, small, medium] }
  # @param type select { choices: [outline, filled] }
  # @param disabled toggle
  # @param icon_position select { choices: ["off", left, right] }
  # @!group Tabler icons
  def primary_with_tabler_icon(
    tabler_icon_name: :arrow_right,
    size: :medium,
    disabled: false,
    type: "outline",
    content: "Button",
    icon_position: :off
  )
    render(ButtonComponent.new(size:, disabled:)) do |c|
      with_tabler_icon(c, tabler_icon_name, icon_position, type:, size:)
      content.to_s
    end
  end
  # @!endgroup

  private

  def with_icon(component, position)
    return if position == :off

    component.with_icon("fal fa-arrow-right", position:)
  end

  def with_tabler_icon(component, icon_name, position, type:, size:)
    return if position == :off

    component.with_tabler_icon(icon_name, position:, type:, size:)
  end
end
