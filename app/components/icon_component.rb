# frozen_string_literal: true

class IconComponent < ApplicationComponent
  include TablerIcons

  ICON_SIZE_CLASS = {
    tiny: "icon-component-tiny",
    small: "icon-component-small",
    medium: "icon-component-medium",
    large: "icon-component-large"
  }.freeze

  param :icon_name, Types::Coercible::String
  option :icon_type,
         Types::Strict::Symbol.enum(:outline, :filled),
         default: -> { :outline }
  option :size,
         Types::Symbol.enum(*ICON_SIZE_CLASS.keys),
         default: -> { :small }

  # The rescue block is needed to test the icon in the lookbook
  def call
    render_icon(
      icon_name,
      icon_type:,
      class: icon_classes,
      stroke_width: 1.25,
      **additional_options
    )
  rescue TablerIcons::Error => e
    content_tag(:span, e)
  end

  private

  def icon_classes
    [
      "icon-component",
      "flex-shrink-0",
      icon_size_class,
      *additional_options.delete(:class)
    ]
  end

  def icon_size_class
    ICON_SIZE_CLASS[size]
  end
end
