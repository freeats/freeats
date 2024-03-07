# frozen_string_literal: true

class ButtonComponentPreview < ViewComponent::Preview
  # @param content text
  # @param size select { choices: [tiny, small, medium, large] }
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

  private

  def with_icon(component, position)
    return if position == :off

    component.with_icon("fal fa-arrow-right", position:)
  end
end
