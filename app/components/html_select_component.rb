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
    select_content =
      if form_or_name.is_a?(ActionView::Helpers::FormBuilder)
        form_or_name.select(
          method,
          "",
          {
            include_blank: required
          },
          disabled:,
          placeholder:,
          readonly:,
          required:,
          "data-html-select-component-target" => "select",
          **additional_options
        )
      else
        select_tag(
          form_or_name,
          "",
          include_blank: required,
          disabled:,
          placeholder:,
          readonly:,
          required:,
          "data-html-select-component-target" => "select",
          **additional_options
        )
      end

    tag.div(class: component_classes + ["html"], **stimulus_controller_options) do
      select_content
    end
  end

  private

  def stimulus_controller_options
    options = { data: { controller: "html-select-component",
                        "html-select-component-item-as-rich-text-value" => item_as_rich_text } }
    if local
      options[:data].merge!(local_options)
    elsif remote
      options[:data].merge!(remote_options)
    end
    options
  end

  def local_options
    { "html-select-component-options-value" => local[:options] }
  end

  def remote_options
    options = {
      "html-select-component-search-url-value" => remote[:search_url],
      "html-select-component-options-value" => remote[:options]
    }
    options["html-select-component-type-value"] = remote[:type] if remote[:type]
    options
  end
end
