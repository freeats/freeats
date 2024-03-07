# frozen_string_literal: true

class LabeledComponent < ApplicationComponent
  renders_one :label, "LabelComponent"

  class LabelComponent < ApplicationComponent
    SIZE_CLASSES = {
      small: "label-component-small col-form-label-sm",
      medium: "label-component-medium col-form-label",
      large: "label-component-large col-form-label-lg"
    }.freeze

    param :text, Types::Strict::String
    option :form, Types::Instance(ActionView::Helpers::FormBuilder), optional: true
    option :for_field, Types::Coercible::String, optional: true
    option :size, Types::Symbol.enum(*SIZE_CLASSES.keys), optional: true, default: -> { :medium }
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
         default: -> { "col-12 col-md-profile" }
  option :right_layout_class, Types::Strict::String,
         optional: true,
         default: -> { "col-12 col-md" }
  option :left_class, Types::Strict::String, optional: true
  option :right_class, Types::Strict::String, optional: true
  option :hidden, Types::Strict::Bool, optional: true, default: -> { false }
  option :design_name, Types::Strict::Hash, optional: true, default: -> { {} }
  option :visible_if_blank, Types::Strict::Bool, optional: true, default: -> { false }

  def call
    return if content.empty? && !visible_if_blank

    tag.div(class: ["row", hidden_class, additional_options.delete(:class)],
            **element_attributes) do
      safe_join(
        [
          tag.div(label, class: [left_layout_class, left_class]),
          tag.div(class: [right_layout_class, right_class]) do
            safe_join([button, content])
          end
        ]
      )
    end
  end

  private

  def button
    return if design_name.blank?

    bs_title =
      if design_name[:class_name].in?(%w[person company])
        "Capitalize and format"
      elsif design_name[:class_name] == "position" && design_name[:disabled]
        "Add roles to be able to format name"
      else
        "Format based on requirements"
      end

    disabled_color = "#6c757d" if design_name[:disabled] # gray-600

    tag.span(
      id: "format-input-button",
      class: "input-group-text inline-edit-icon",
      data: {
        name_designing_target: "NameInputButton",
        bs_toggle: :tooltip,
        bs_title:,
        bs_placement: :left
      }
    ) do
      tag.i(class: "fas fa-text-size", style: "color: #{disabled_color}")
    end
  end

  def hidden_class
    "hidden" if hidden
  end

  def element_attributes
    return additional_options if design_name[:disabled] || design_name.blank?

    composed_name = design_name[:composed_name]
    path =
      case design_name[:class_name]
      when "person" then format_person_name_api_v1_formatting_path
      when "company" then format_company_name_api_v1_formatting_path
      end

    attributes = { **additional_options, data: { controller: "name-designing" } }
    attributes[:data][:name_designing_path_value] = path if path.present?
    attributes[:data][:name_designing_composed_name_value] = composed_name if composed_name.present?

    attributes
  end
end
