# frozen_string_literal: true

class LabeledComponent < ApplicationComponent
  renders_one :label, "LabelComponent"

  class LabelComponent < ApplicationComponent
    SIZE_CLASSES = {
      small: "label-component-small col-form-label-sm",
      medium: "label-component-medium col-form-label"
    }.freeze

    param :text, Types::Strict::String
    option :form, Types::Instance(ActionView::Helpers::FormBuilder), optional: true
    option :for_field, Types::Coercible::String, optional: true
    option :size, Types::Symbol.enum(*SIZE_CLASSES.keys), optional: true, default: -> { :small }
    option :color_class, Types::Strict::String,
           optional: true,
           default: -> { form || for_field ? "text-gray-900" : "text-gray-600" }

    def call
      css_class = [additional_options.delete(:class), size_class, color_class]

      if form
        form.label(
          for_field || text.parameterize(separator: "_"),
          text,
          class: css_class,
          **additional_options
        )
      elsif for_field
        label_tag(for_field, text, class: css_class, **additional_options)
      else
        tag.div(text, class: css_class, **additional_options)
      end
    end

    private

    def size_class
      SIZE_CLASSES[size]
    end
  end

  option :left_layout_class, Types::Strict::String,
         optional: true,
         default: -> { "col-12 col-md-3" }
  option :right_layout_class, Types::Strict::String,
         optional: true,
         default: -> { "col-12 col-md" }
  option :left_class, Types::Strict::String, optional: true
  option :right_class, Types::Strict::String, optional: true
  option :hidden, Types::Strict::Bool, optional: true, default: -> { false }
  option :visible_if_blank, Types::Strict::Bool, optional: true, default: -> { false }

  def call
    return if content.blank? && !visible_if_blank

    tag.div(class: ["row", hidden_class, additional_options.delete(:class)],
            **additional_options) do
      safe_join(
        [
          tag.div(label, class: [left_layout_class, left_class]),
          tag.div(class: [right_layout_class, right_class]) do
            content
          end
        ]
      )
    end
  end

  private

  def hidden_class
    "hidden" if hidden
  end
end
