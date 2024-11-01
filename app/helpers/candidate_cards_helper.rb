# frozen_string_literal: true

module CandidateCardsHelper
  def candidate_card_edit(
    card_name,
    candidate,
    header: nil,
    target_url: nil,
    form_options: {},
    &
  )
    card_edit(
      card_name:,
      target_model: candidate,
      target_url: target_url || public_send(
        :"update_card_ats_#{candidate.class.name.downcase}_path", candidate
      ),
      header:,
      form_options:,
      &
    )
  end

  def candidate_turn_array_to_string_with_line_breakers(array)
    array.filter(&:present?)
         .join(", ")
         .gsub(/([\[+`;,{-~])/) { Regexp.last_match(1).to_s }
  end

  def candidate_card_contact_info_has_data?(candidate)
    candidate.candidate_emails.present? ||
      candidate.phones.present? ||
      candidate.links.present? ||
      candidate.skype.present? ||
      candidate.telegram.present? ||
      candidate.candidate_source.present?
  end

  def candidate_card_source(candidate)
    return if candidate.candidate_source.blank?

    candidate.candidate_source.name
  end

  def candidate_card_phone_links(candidate)
    return if candidate.candidate_phones.blank?

    tag.div(class: "d-flex flex-row flex-wrap column-gap-2 row-gap-1") do
      safe_join(
        candidate.candidate_phones.map do |phone|
          link_to_with_copy_popover_button(
            CandidatePhone.international_phone(phone.phone),
            "tel:#{phone.phone}"
          )
        end
      )
    end
  end

  def candidate_card_email_links(candidate)
    return if candidate.candidate_email_addresses.blank?

    safe_join(
      [candidate.candidate_email_addresses.map do |e|
         tag.div(class: "d-flex column-gap-1") do
           link_to_with_copy_popover_button(
             e.address,
             "mailto:#{e[:address]}",
             data: { turbo_frame: "_top" },
             class: "text-truncate"
           )
         end
       end]
    )
  end

  def candidate_card_beautiful_links(candidate)
    return if candidate.candidate_links.blank?

    beautiful_links = candidate.sorted_candidate_links.map do |link|
      account_link_display(link.url)
    end

    safe_join [
      tag.div(class: "row flex-wrap links-row gx-2 align-items-center") do
        safe_join [
          beautiful_links
        ]
      end
    ]
  end

  def candidate_card_chat_links(candidate)
    chat_links = []
    if candidate.telegram.present?
      icon = inline_svg_tag("telegram.svg", { height: 18, width: 18, class: "telegram-icon" })
      link = "http://t.me/#{candidate.telegram.delete_prefix('@')}"
      data = { copy_link_tooltip: candidate.telegram }
      klass = "col-auto d-flex text-decoration-none link-font telegram"

      chat_links << link_to_with_copy_popover_button(
        icon, link, data:, class: klass
      )
    end
    if candidate.skype.present?
      icon = inline_svg_tag("skype.svg", { height: 18, width: 18, class: "skype-icon" })
      link = "skype:#{candidate.skype}"
      data = { copy_link_tooltip: candidate.skype }
      klass = "col-auto d-flex text-decoration-none link-font skype"

      chat_links << link_to_with_copy_popover_button(
        icon, link, data:, class: klass
      )
    end
    return if chat_links.empty?

    tag.div(class: "row links-row gx-2 align-items-center") do
      safe_join(chat_links)
    end
  end

  def candidate_card_cover_letter_copy_button(candidate)
    render(
      IconComponent.new(
        :copy,
        class: "btn btn-link p-0 ms-2",
        data: {
          controller: "copy-to-clipboard",
          clipboard_text: candidate.cover_letter.body.to_html,
          clipboard_plain_text: candidate.cover_letter.to_plain_text,
          bs_title: "Copied!",
          bs_trigger: :manual
        }
      )
    )
  end
end
