# frozen_string_literal: true

class TextInputComponent < ApplicationComponent
  renders_one :subscript, "SubscriptComponent"

  class SubscriptComponent < ApplicationComponent
    param :text, Types::Strict::String
    option :id, Types::Strict::String, optional: true, default: -> { SecureRandom.alphanumeric(10) }

    def call
      tag.span(text, id:, class: "text-input-component-subscript")
    end
  end

  DEFAULT_CLASSES = %w[
    form-control
    text-input-component-default
  ].freeze

  SIZE_CLASSES = {
    tiny: "text-input-component-tiny",
    small: "text-input-component-small",
    medium: "text-input-component-medium"
  }.freeze

  param :form_or_name, Types::Instance(ActionView::Helpers::FormBuilder) |
                       Types::Coercible::String
  option :method, Types::Coercible::String, optional: true
  option :value, Types::Coercible::String, optional: true
  option :size, Types::Symbol.enum(*SIZE_CLASSES.keys),
         optional: true,
         default: -> { :small }
  option :disabled, Types::Strict::Bool, optional: true, default: -> { false }
  option :readonly, Types::Strict::Bool, optional: true, default: -> { false }
  option :placeholder, Types::Strict::String | Types::Strict::Bool, optional: true

  def call
    additional_options[:aria] = { describedby: subscript.id } if subscript

    input =
      if form_or_name.is_a?(ActionView::Helpers::FormBuilder)
        text_input(form_or_name)
      elsif form_or_name.is_a?(String)
        text_field_tag(form_or_name)
      else
        raise ArgumentError, "The first argument is neither FormBuilder nor String"
      end

    if subscript
      tag.div do
        safe_join([input, subscript])
      end
    else
      input
    end
  end

  private

  def text_input(form)
    value_option = value.present? ? { value: } : {}
    form.text_field(
      method,
      **value_option,
      class: [
        DEFAULT_CLASSES,
        size_class,
        disabled_class,
        additional_options.delete(:class)
      ],
      disabled:,
      readonly:,
      placeholder: placeholder_computed,
      **additional_options
    )
  end

  def text_field_tag(name)
    helpers.text_field_tag(
      name,
      value,
      class: [
        DEFAULT_CLASSES,
        size_class,
        disabled_class,
        additional_options.delete(:class)
      ],
      disabled:,
      readonly:,
      placeholder: placeholder_computed,
      **additional_options
    )
  end

  def size_class
    SIZE_CLASSES[size]
  end

  def disabled_class
    "text-input-component-disabled" if disabled || readonly
  end

  # When `placeholder` is `true`, use a humanized field name.
  def placeholder_computed
    if placeholder.is_a?(String)
      placeholder
    elsif placeholder == true
      if form_or_name.is_a?(String)
        form_or_name.humanize
      elsif method.present?
        method.humanize
      end
    end
  end
end
