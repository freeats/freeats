# frozen_string_literal: true

class PillSelectComponent < SelectComponent
  option :include_hidden, Types::Strict::Bool, default: -> { false }

  def call
    select_content =
      if form_or_name.is_a?(ActionView::Helpers::FormBuilder)
        form_or_name.select(
          method,
          compose_options_for_select,
          {
            include_hidden:
          },
          multiple: true,
          placeholder:,
          disabled:,
          readonly:,
          "data-pill-select-component-target": "select",
          **additional_options
        )
      else
        select_tag(
          form_or_name,
          compose_options_for_select,
          multiple: true,
          placeholder:,
          disabled:,
          readonly:,
          "data-pill-select-component-target": "select",
          **additional_options
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
    options
  end

  def remote_options
    { "pill-select-component-search-url-value" => remote[:search_url] }
  end
end
