# frozen_string_literal: true

class SingleSelectComponent < SelectComponent
  option :blank_option, Types::Strict::Bool | Types::Strict::String, default: -> { false }
  option :required, Types::Strict::Bool, default: -> { false }

  def call
    select_content =
      if form_or_name.is_a?(ActionView::Helpers::FormBuilder)
        form_or_name.select(
          method,
          compose_options_for_select,
          {
            include_blank: blank_option || required
          },
          disabled:,
          placeholder:,
          readonly:,
          required:,
          "data-single-select-component-target": "select",
          **additional_options
        )
      else
        select_tag(
          form_or_name,
          compose_options_for_select,
          include_blank: blank_option || required,
          disabled:,
          placeholder:,
          readonly:,
          required:,
          "data-single-select-component-target": "select",
          **additional_options
        )
      end

    tag.div(class: component_classes + ["single"], **stimulus_controller_options) do
      select_content
    end
  end

  private

  def stimulus_controller_options
    options = { data: { controller: "single-select-component" } }
    options[:data].merge!(remote_options) if remote
    options[:data].merge!(allow_empty_option) if blank_option.present?
    options
  end

  def remote_options
    { "single-select-component-search-url-value" => remote[:search_url] }
  end

  def allow_empty_option
    { "single-select-component-allow-empty-option-value" => true }
  end
end
