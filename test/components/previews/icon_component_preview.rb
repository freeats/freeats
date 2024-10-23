# frozen_string_literal: true

class IconComponentPreview < ViewComponent::Preview
  # @param tabler_icon_name text
  # @param type select { choices: [outline, filled] }
  # @param size select { choices: [tiny, small, medium] }
  def icon(tabler_icon_name: :pointer, type: :outline, size: :small)
    render(IconComponent.new(tabler_icon_name, type:, size:))
  end
end
