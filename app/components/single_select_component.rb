# frozen_string_literal: true

class SingleSelectComponent < SelectComponent
  option :include_blank, Types::Strict::Bool | Types::Strict::String, default: -> { false }
  option :required, Types::Strict::Bool, default: -> { false }

  def call
    common_options = {
      id: compose_id,
      disabled:,
      placeholder:,
      readonly:,
      required:,
      "data-single-select-component-target": "select",
      **additional_options
    }

    select_content =
      if form_or_name.is_a?(ActionView::Helpers::FormBuilder)
        form_or_name.select(
          method,
          compose_options_for_select,
          {
            include_blank: include_blank || required
          },
          **common_options
        )
      else
        select_tag(
          form_or_name,
          compose_options_for_select,
          include_blank: include_blank || required,
          **common_options
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
    options[:data].merge!(allow_empty_option) if include_blank.present?
    options[:data].merge!(set_body_as_dropdown_parent) if anchor_dropdown_to_body.present?

    options
  end

  def remote_options
    { single_select_component_search_url_value: remote[:search_url] }
  end

  def allow_empty_option
    { single_select_component_allow_empty_option_value: true }
  end

  def set_body_as_dropdown_parent
    { single_select_component_dropdown_parent_value: "body" }
  end
end
