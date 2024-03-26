# frozen_string_literal: true

# Original source: https://github.com/basecamp/trix/issues/55#issuecomment-335794073
module TrixHelper
  def trix_sanitize_and_add_target_blank_to_links(html)
    doc = Nokogiri::HTML(html)
    doc.css("a").each do |link|
      link["target"] = "_blank"
      link["rel"] = "noopener noreferrer"
    end
    sanitize(doc.to_s, attributes: %w[href target rel class])
  end

  # The parameter :options currently accepts the following options:
  #   value: TrixHtml           - the default value of the input
  #   skipped_options: [String] - name of buttons that should be hidden in the toolbar
  #   data: Hash                - data-attributes (e.g. controller/action)
  #   placeholder: String       - a placeholder for an empty input
  #   class: String             - additional classes for the input
  #   editor_id: Integer        - DOM ID for the input
  #   toolbar_id: Integer       - DOM ID for the toolbar
  #   input: String             - input name attribute
  def trix_editor(
    form,
    object_name,
    options = {}
  )
    options[:value] ||= form.object&.public_send(:"#{object_name}")
    options[:skipped_options]&.map! { "trix-no-#{_1}" }&.join(" ")
    options[:data] ||= {}
    options[:editor_id] ||= "#{form.object.class.name.downcase}_#{object_name}"

    toolbar_id = [options[:toolbar_id].presence || object_name, "-trix-toolbar"].join

    tag.div(
      data: { controller: "trix-toolbar",
              action: "trix-selection-change->trix-toolbar#update" }
    ) do
      safe_join(
        [
          tag.trix_toolbar(id: toolbar_id, class: options[:skipped_options]&.join(" ")),
          form.rich_text_area(
            object_name,
            class: [
              "trix-content-custom p-0 border-0 shadow-none", options[:class]
            ].join(" "),
            toolbar: toolbar_id,
            id: options[:editor_id],
            input: options[:input].presence || [form.object_name, object_name].join("_"),
            placeholder: (options[:placeholder] || object_name).to_s.humanize,
            value: options[:value],
            data: {
              action: [
                "trix-before-paste->input-utils#pasteAutolink",
                options.dig(:data, :action)
              ].join(" ")
            }.merge(options[:data].except(:action))
          )
        ]
      )
    end
  end
end
