# frozen_string_literal: true

class IconButtonComponent < IconComponent
  ICON_BUTTON_VARIANTS = %w[
    default
    ghost
  ].freeze

  SIZE_CLASSES = {
    tiny: "icon-tiny",
    small: "icon-small",
    medium: "icon-medium"
  }.freeze

  option :href,
         Types::Strict::Hash.schema(
           url: Types::Strict::String,
           target?: Types::Strict::Symbol.enum(:_self, :_blank, :_parent, :_top)
         ).optional, optional: true
  option :variant, Types::Coercible::String.enum(*ICON_BUTTON_VARIANTS), default: -> { :default }
  option :type, Types::Symbol.enum(:button, :submit, :reset), default: -> { :submit }
  option :disabled, Types::Strict::Bool, default: -> { false }
  option :size, Types::Strict::Symbol.enum(*SIZE_CLASSES.keys), default: -> { :small }
  option :additional_icon_options, Types::Strict::Hash, default: -> { {} }

  # All untyped parameters from `additional_options` assigned to the button.
  # And the parameters from `additional_icon_options` are moved to `additional_options`.
  # This is needed for use in IconComponent, since that component uses super to render it.
  def before_render
    @additional_button_options = @additional_options.dup
    @additional_options = additional_icon_options
  end

  def call
    if href.present? && !disabled
      return link_to(
        href[:url],
        target: href[:target],
        class: btn_classes,
        disabled:,
        **@additional_button_options
      ) { super }
    end

    content_tag(
      :button,
      class: btn_classes,
      disabled:,
      type:,
      **@additional_button_options
    ) { super }
  end

  private

  def btn_classes
    [
      "icon-button-component",
      disabled_class,
      variant,
      size_class,
      @additional_button_options.delete(:class)
    ].compact
  end

  def disabled_class
    "disabled" if disabled
  end

  def size_class
    SIZE_CLASSES[size]
  end
end
