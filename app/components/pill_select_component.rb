# frozen_string_literal: true

class PillSelectComponent < SelectComponent
  option :include_hidden, Types::Strict::Bool, default: -> { false }
  option :allow_create_new_option, Types::Strict::Bool, default: -> { false }

  def call
    common_options = {
      id: compose_id,
      multiple: true,
      placeholder:,
      disabled:,
      readonly:,
      "data-pill-select-component-target": "select",
      **additional_options
    }

    select_content =
      if form_or_name.is_a?(ActionView::Helpers::FormBuilder)
        form_or_name.select(
          method,
          compose_options_for_select,
          {
            include_hidden:
          },
          **common_options
        )
      else
        select_tag(
          form_or_name,
          compose_options_for_select,
          **common_options
        )
      end

    tag.div(class: component_classes + ["pill"], **stimulus_controller_options) do
      select_content
    end
  end

  private

  def stimulus_controller_options
    options = { data: { controller: "pill-select-component" } }
    options[:data].merge!(remote_options) if remote
    options[:data].merge!(create_new_option) if allow_create_new_option
    options
  end

  def remote_options
    { pill_select_component_search_url_value: remote[:search_url] }
  end

  def create_new_option
    { pill_select_component_create_new_option_value: true }
  end
end
