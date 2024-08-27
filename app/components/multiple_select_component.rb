# frozen_string_literal: true

class MultipleSelectComponent < SelectComponent
  option :include_hidden, Types::Strict::Bool, default: -> { false }
  option :required, Types::Strict::Bool, default: -> { false }
  option :instant_submit, Types::Strict::Bool, default: -> { false }

  def call
    common_options = {
      id: compose_id,
      disabled:,
      placeholder:,
      readonly:,
      required:,
      multiple: true,
      "data-multiple-select-component-target": "select",
      **additional_options
    }

    select_content =
      if form_or_name.is_a?(ActionView::Helpers::FormBuilder)
        form_or_name.select(
          method,
          compose_options_for_select,
          {
            include_hidden:,
            include_blank: required
          },
          **common_options
        )
      else
        select_tag(
          form_or_name,
          compose_options_for_select,
          include_blank: required,
          **common_options
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
      multiple_select_component_button_group_size_value: BUTTON_GROUP_SIZE_CLASSES[size],
      multiple_select_component_instant_submit_value: instant_submit
    } }
    options[:data].merge!(remote_options) if remote
    options
  end

  def remote_options
    { multiple_select_component_search_url_value: remote[:search_url] }
  end
end
