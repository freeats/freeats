# frozen_string_literal: true

module AccountLinksHelper
  PATH = "icons/"

  def account_link_display(link, klass: "col-auto")
    account_link = AccountLink.new(link)
    domain = account_link.domain
    unless domain
      return link_to(
        tag.i(
          "",
          class: "fas fa-globe",
          data: { bs_toggle: "tooltip", title: account_link_short_name(link) }
        ),
        account_link.humanize,
        target: "_blank",
        class: klass,
        style: "font-size: 18px; line-height: 20px"
      )
    end

    icon =
      case domain[:type]
      when :svg
        inline_svg_tag(domain[:params].first, **domain[:params].second)
      when :font_awesome
        tag.i("", **domain[:params].first)
      else
        image_tag(
          "#{PATH}#{domain[:class] || account_link.low_level_domain}" \
          "_icon.png",
          **(domain[:params]&.first.presence || { height: 18, width: 18 })
        )
      end
    link_class = "#{domain[:class] || account_link.low_level_domain}-icon #{klass}"

    link_to(icon, link, target: "_blank",
                        class: "d-flex text-decoration-none #{link_class}")
  end

  def account_outdated_link_display(link, klass: "col-auto disabled")
    account_link = AccountLink.new(link)
    domain = account_link.domain
    unless domain
      return tag.span(
        class: "#{klass} link-primary",
        data: { "bs-toggle": "tooltip", "bs-title": t("core.outdated") },
        style: "font-size: 18px; line-height: 20px"
      ) do
        tag.i(
          "",
          class: "fas fa-globe"
        )
      end
    end

    icon =
      case domain[:type]
      when :svg
        inline_svg_tag(domain[:params].first, **domain[:params].second)
      when :font_awesome
        tag.i("", **domain[:params].first)
      else
        image_tag(
          "#{PATH}#{domain[:class] || account_link.low_level_domain}" \
          "_icon.png",
          **(domain[:params]&.first.presence || { height: 18, width: 18 })
        )
      end
    link_class = "#{domain[:class] || account_link.low_level_domain}-icon #{klass}"

    tag.span(
      class: "d-flex text-decoration-none #{link_class}",
      data: { "bs-toggle": "tooltip", "bs-title": t("core.outdated") }
    ) do
      icon
    end
  end

  def account_link_short_name(link)
    if link.length > 40
      "#{link[0..30]}...#{link[-5..]}"
    else
      link
    end
  end
end
