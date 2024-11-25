# frozen_string_literal: true

module CardsHelper
  def card_header(title:, icon_style:, &block)
    content_tag(:div, class: "d-inline-block align-items-center text-truncate") do
      concat(render(IconComponent.new(icon_style, size: :medium, class: "me-2")))
      concat(title)
      concat(capture(&block)) if block
    end
  end

  def card_show(card_name, target_model: nil, header: nil, control_button: :edit, &)
    render("shared/profile/card_show",
           card_name:,
           target_model:,
           header: header || card_name.humanize,
           control_button:,
           &)
  end

  def card_edit(card_name:, target_model:, target_url:, header: nil, form_options: {}, &)
    card_name_input = hidden_field_tag(:card_name, card_name, id: nil)
    partial = render("shared/profile/card_edit",
                     card_name:,
                     header: header || card_name.humanize,
                     target_model:,
                     target_url:,
                     form_options:,
                     &)
    fragment = Nokogiri::HTML.fragment(partial)
    fragment.at("form").add_child(card_name_input)
    raw(fragment.to_s) # rubocop:disable Rails/OutputSafety
  end

  def card_row(
    left,
    right,
    options = {}
  )
    return if right.blank?

    render("shared/profile/card_row",
           left:,
           right:,
           options:)
  end

  def card_empty(card_name, target_model: nil, header: nil, path: nil, tooltip_text: nil)
    render "shared/profile/card_empty", card_name:, target_model:, header:, path:, tooltip_text:
  end
end
