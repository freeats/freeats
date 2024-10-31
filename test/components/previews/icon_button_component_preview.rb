# frozen_string_literal: true

class IconButtonComponentPreview < ViewComponent::Preview
  # @param tabler_icon_name text
  # @param icon_type select { choices: [outline, filled] }
  # @param size select { choices: [tiny, small, medium] }
  # @!group Variants
  def default_variant(tabler_icon_name: :pointer, icon_type: :outline, size: :small)
    render(IconButtonComponent.new(tabler_icon_name, icon_type:, size:))
  end

  def ghost_variant(tabler_icon_name: :pointer, icon_type: :outline, size: :small, variant: :ghost)
    render(IconButtonComponent.new(tabler_icon_name, icon_type:, size:, variant:))
  end
  # @!endgroup
end
