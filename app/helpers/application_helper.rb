# frozen_string_literal: true

module ApplicationHelper
  PRIORITY_COLORS = {
    "low" => "code-green",
    "medium" => "code-yellow",
    "high" => "code-red"
  }.freeze

  def options_for_priority(collection, selected_value = nil)
    options =
      collection.map do |_, value|
        {
          text: value.humanize,
          value:,
          color: PRIORITY_COLORS[value],
          selected: selected_value == value
        }
      end
    safe_join(
      options.map do |option|
        tag.option(value: option[:value], selected: option[:selected]) do
          tag.div(class: "d-inline-flex align-items-center") do
            safe_join [
              tag.i("", class: "fas fa-solid fa-circle pe-2 #{option[:color]}"),
              option[:text]
            ]
          end
        end
      end
    )
  end
end
