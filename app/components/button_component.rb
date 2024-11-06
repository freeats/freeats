# frozen_string_literal: true

class ButtonComponent < ApplicationComponent
  renders_one :icon, "InnerIconComponent"

  class InnerIconComponent < IconComponent
    ICON_POSITION = {
      left: "",
      right: "order-last"
    }.freeze

    option :position,
           Types::Symbol.enum(*ICON_POSITION.keys),
           optional: true,
           default: -> { :right }

    def before_render
      additional_options[:class] = [*additional_options[:class], position_class]
    end

    private

    def position_class
      ICON_POSITION[position]
    end
  end

  VARIANT_CLASSES = {
    primary: "btn-primary",
    secondary: "btn-outline-primary",
    cancel: "",
    danger: "btn-danger",
    danger_secondary: "btn-outline-danger",
    custom: ""
  }.freeze

  SIZE_CLASSES = {
    tiny: "btn-tiny",
    small: "btn-small",
    medium: "btn-medium"
  }.freeze

  DEFAULT_CLASSES = %w[
    btn
    d-inline-flex
    gap-2
    align-items-center
    text-nowrap
  ].freeze

  option :variant, Types::Symbol.enum(*VARIANT_CLASSES.keys), default: -> { :primary }
  option :size, Types::Symbol.enum(*SIZE_CLASSES.keys), default: -> { :small }
  option :disabled, Types::Strict::Bool, default: -> { false }
  option :hidden, Types::Strict::Bool, default: -> { false }
  option :type, Types::Symbol.enum(:button, :submit, :reset), default: -> { :submit }
  option :tooltip_title, Types::Strict::String, optional: true

  # Needed to place content inside the button horizontally.
  # Responsive classes just pass them to a `:class` additional option.
  option :flex_content_position,
         Types::Strict::Symbol.enum(:start, :end, :center),
         default: -> { :center }

  def call
    button_content =
      tag.button(
        class: [
          DEFAULT_CLASSES,
          variant_class,
          size_class,
          hidden_class,
          disabled_class,
          flex_content_position_class,
          additional_options.delete(:class)
        ],
        disabled:,
        type:,
        **additional_options
      ) do
        safe_join([icon, content])
      end

    if tooltip_title
      tag.span(class: "d-inline-block", data: { bs_toggle: :tooltip }, title: tooltip_title) do
        button_content
      end
    else
      button_content
    end
  end

  private

  def variant_class
    VARIANT_CLASSES[variant]
  end

  def size_class
    SIZE_CLASSES[size]
  end

  def flex_content_position_class
    ["justify-content", flex_content_position].join("-")
  end

  def disabled_class
    "disabled" if disabled
  end

  def hidden_class
    "d-none" if hidden
  end
end
