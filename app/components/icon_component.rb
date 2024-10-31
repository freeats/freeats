# frozen_string_literal: true

class IconComponent < ApplicationComponent
  include TablerIcons

  ICON_SIZES = {
    tiny: 15,
    small: 17,
    medium: 20
  }.freeze

  param :icon_name, Types::Coercible::String
  option :icon_type,
         Types::Strict::Symbol.enum(:outline, :filled),
         default: -> { :outline }
  option :color, Types::Strict::String.optional, optional: true
  option :size,
         Types::Symbol.enum(*ICON_SIZES.keys) | Types::Strict::Integer,
         default: -> { :small }

  # The rescue block is needed to test the icon in the lookbook
  def call
    render_icon(
      icon_name,
      icon_type:,
      size: icon_size,
      color:,
      stroke_width: 1.25,
      **additional_options
    )
  rescue TablerIcons::Error => e
    content_tag(:span, e)
  end

  private

  def icon_size
    ICON_SIZES[size] || size
  end
end
