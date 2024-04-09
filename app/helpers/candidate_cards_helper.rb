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
         .gsub(/([\[+`;,{-~])/) { "#{Regexp.last_match(1)}&#8203;" }
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
          tooltip_text = [
            "Source: #{phone.source.humanize}",
            "Type: #{phone.type&.capitalize || 'None'}",
            "Status: #{phone.status.capitalize}"
          ].join("<br>")
          phone_tooltip =
            tag.span(class: "ms-1",
                     data: { "bs-toggle" => "tooltip",
                             "bs-title" => tooltip_text,
                             "bs-html" => true }) do
              tag.i("", class: "far fa-info-circle")
            end
          if phone.status != "current"
            tag.span do
              safe_join([tag.s(phone.phone), phone_tooltip])
            end
          else
            tag.span do
              safe_join([
                          link_to_with_copy_popover_button(
                            CandidatePhone.international_phone(phone.phone),
                            "tel:#{phone.phone}"
                          ),
                          phone_tooltip
                        ])
            end
          end
        end
      )
    end
  end

  def candidate_card_email_links(candidate)
    return if candidate.candidate_email_addresses.blank?

    safe_join(
      [candidate.candidate_email_addresses.map do |e|
         tooltip_text = [
           "Source: #{e.source.humanize}",
           "Type: #{e.type.capitalize}",
           "Status: #{e.status.capitalize}"
         ].join("<br>")
         email_tooltip =
           tag.span(class: "flex-shrink-0",
                    data: { "bs-toggle" => "tooltip",
                            "bs-title" => tooltip_text,
                            "bs-html" => true }) do
             tag.i("", class: "far fa-info-circle")
           end

         if e.status != "current"
           tag.div(class: "d-flex column-gap-1") do
             safe_join([tag.s(e.address, class: "text-truncate"), email_tooltip])
           end
         else
           tag.div(class: "d-flex column-gap-1") do
             safe_join [
               link_to_with_copy_popover_button(
                 e.address,
                 "mailto:#{e[:address]}",
                 data: { turbo_frame: "_top" },
                 class: "text-truncate"
               ),
               email_tooltip
             ]
           end
         end
       end]
    )
  end

  def candidate_card_beautiful_links(candidate)
    return if candidate.candidate_links.blank?

    beautiful_links = candidate.sorted_links.map do |link|
      if link.status == "current"
        account_link_display(link.url)
      else
        account_outdated_link_display(link.url)
      end
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
      chat_links << link_to_with_copy_popover_button(
        tag.i("", class: "fab fa-telegram telegram-icon"),
        "http://t.me/#{candidate.telegram.delete_prefix('@')}",
        data: { copy_link_tooltip: candidate.telegram },
        class: "col-auto d-flex text-decoration-none link-font skype-icon"
      )
    end
    if candidate.skype.present?
      chat_links << link_to_with_copy_popover_button(
        tag.i("", class: "fab fa-skype"),
        "skype:#{candidate.skype}",
        data: { copy_link_tooltip: candidate.skype },
        class: "col-auto d-flex text-decoration-none link-font skype-icon"
      )
    end
    return if chat_links.empty?

    tag.div(class: "row links-row gx-2 align-items-center") do
      safe_join(chat_links)
    end
  end

  def candidate_card_cover_letter_copy_button(candidate)
    tag.button(
      tag.i(class: "far fa-copy"),
      type: "button",
      class: "btn btn-link p-0 align-top ms-2",
      data: {
        controller: "copy-to-clipboard",
        clipboard_text: candidate.cover_letter.body.to_html,
        clipboard_plain_text: candidate.cover_letter.to_plain_text,
        bs_title: "Copied!",
        bs_trigger: "manual"
      }
    )
  end
end
