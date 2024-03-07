# frozen_string_literal: true

class MultipleSelectComponent < SelectComponent
  option :include_hidden, Types::Strict::Bool, default: -> { false }
  option :required, Types::Strict::Bool, default: -> { false }

  def call
    select_content =
      if form_or_name.is_a?(ActionView::Helpers::FormBuilder)
        form_or_name.select(
          method,
          compose_options_for_select,
          {
            include_hidden:,
            include_blank: required
          },
          disabled:,
          placeholder:,
          readonly:,
          required:,
          multiple: true,
          "data-multiple-select-component-target": "select",
          **additional_options
        )
      else
        select_tag(
          form_or_name,
          compose_options_for_select,
          include_blank: required,
          disabled:,
          placeholder:,
          readonly:,
          required:,
          multiple: true,
          "data-multiple-select-component-target": "select",
          **additional_options
        )
      end

    tag.div(class: component_classes + ["multiple"], **stimulus_controller_options) do
      select_content
    end
  end

  private

  def stimulus_controller_options
    options = { data: {
      controller: "multiple-select-component",
      "multiple-select-component-button-group-size-value" => BUTTON_GROUP_SIZE_CLASSES[size]
    } }
    options[:data].merge!(remote_options) if remote
    options
  end

  def remote_options
    { "multiple-select-component-search-url-value" => remote[:search_url] }
  end
end
