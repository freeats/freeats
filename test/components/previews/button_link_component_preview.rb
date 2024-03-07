# frozen_string_literal: true

class ButtonLinkComponentPreview < ViewComponent::Preview
  # @param content text
  # @param size select { choices: [tiny, small, medium, large] }
  # @param disabled toggle
  # @param icon select { choices: ["off", left, right] }
  # @!group Variants
  def primary(size: :medium, disabled: false, content: "Button", icon: :off)
    render(ButtonLinkComponent.new("#", size:, disabled:)) do |c|
      with_icon(c, icon)
      content.to_s
    end
  end

  def secondary(size: :medium, disabled: false, content: "Button", icon: :off)
    render(ButtonLinkComponent.new("#", variant: :secondary, size:, disabled:)) do |c|
      with_icon(c, icon)
      content.to_s
    end
  end

  def cancel(size: :medium, disabled: false, content: "Button", icon: :off)
    render(ButtonLinkComponent.new("#", variant: :cancel, size:, disabled:)) do |c|
      with_icon(c, icon)
      content.to_s
    end
  end

  def danger(size: :medium, disabled: false, content: "Button", icon: :off)
    render(ButtonLinkComponent.new("#", variant: :danger, size:, disabled:)) do |c|
      with_icon(c, icon)
      content.to_s
    end
  end

  def danger_secondary(size: :medium, disabled: false, content: "Button", icon: :off)
    render(ButtonLinkComponent.new("#", variant: :danger_secondary, size:, disabled:)) do |c|
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
