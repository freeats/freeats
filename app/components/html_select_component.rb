# frozen_string_literal: true

# Rails do not allow the rendering of rich text in the dropdown menu or in the selected options.
# We have to pass the rich text as a string to the stimulus controller and parse it there.
class HtmlSelectComponent < SelectComponent
  # This option is used to define how we want to render the selected option,
  # as a plain text or as a rich text.
  option :item_as_rich_text, Types::Strict::Bool, default: -> { false }
  option :required, Types::Strict::Bool, default: -> { false }

  option :local,
         Types::Strict::Hash.schema(options: Types::Strict::String),
         optional: true

  option :remote,
         Types::Strict::Hash.schema(
           search_url: Types::Strict::String,
           type?: Types::Strict::Symbol,
           options?: Types::Strict::String.optional
         ),
         optional: true

  def call
    common_options = {
      id: compose_id,
      disabled:,
      placeholder:,
      readonly:,
      required:,
      "data-html-select-component-target": "select",
      **additional_options
    }

    select_content =
      if form_or_name.is_a?(ActionView::Helpers::FormBuilder)
        form_or_name.select(
          method,
          "",
          {
            include_blank: required
          },
          **common_options
        )
      else
        select_tag(
          form_or_name,
          "",
          include_blank: required,
          **common_options
        )
      end

    tag.div(class: component_classes + ["html"], **stimulus_controller_options) do
      select_content
    end
  end

  private

  def stimulus_controller_options
    options = { data: { controller: "html-select-component",
                        html_select_component_item_as_rich_text_value: item_as_rich_text,
                        html_select_component_with_chevron_value: local? } }
    options[:data].merge!(set_body_as_dropdown_parent) if anchor_dropdown_to_body.present?

    if local
      options[:data].merge!(local_options)
    elsif remote
      options[:data].merge!(remote_options)
    end
    options
  end

  def local_options
    { html_select_component_options_value: local[:options] }
  end

  def remote_options
    options = {
      html_select_component_search_url_value: remote[:search_url],
      html_select_component_options_value: remote[:options]
    }
    options[:html_select_component_type_value] = remote[:type] if remote[:type]
    options
  end

  def set_body_as_dropdown_parent
    { html_select_component_dropdown_parent_value: "body" }
  end
end
