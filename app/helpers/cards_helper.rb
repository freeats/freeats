# frozen_string_literal: true

module CardsHelper
  def card_header(title:, icon_style:, &block)
    content_tag(:div, class: "align-items-center text-truncate") do
      concat(content_tag(:i, nil, class: "fal #{icon_style} me-2", style: "width: 20px;"))
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

  # TODO: remove this method
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

  def card_help_text(company = nil)
    public_company_link =
      if company.nil? || company.client&.new_record? || company.anonymous?
        "publicly visible"
      else
        link_to(
          "publicly visible",
          public_client_path(company.slug),
          target: :_blank
        )
      end
    tag.span(
      safe_join(["Please note that the fields marked in bold are ", public_company_link]),
      class: "form-text text-muted"
    )
  end
end
