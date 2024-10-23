# frozen_string_literal: true

class IconComponent < ApplicationComponent
  ICON_SIZES = {
    tiny: 15,
    small: 17,
    medium: 20
  }.freeze

  param :name, Types::Coercible::String
  option :type, Types::Coercible::Symbol.enum(:outline, :filled), default: -> { :outline }
  option :size,
         Types::Symbol.enum(*ICON_SIZES.keys) | Types::Strict::Integer,
         default: -> { :small }

  # The rescue block is needed to test the icon in the lookbook
  def call
    tabler_icon(icon_name, size: icon_size, stroke_width: 1.25, **additional_options)
  rescue TablerIconsRuby::Error
    nil
  end

  private

  def icon_name
    type == :filled ? "#{name}-filled" : name
  end

  def icon_size
    ICON_SIZES[size] || size
  end
end
