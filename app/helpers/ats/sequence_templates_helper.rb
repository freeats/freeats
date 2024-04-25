# frozen_string_literal: true

module ATS::SequenceTemplatesHelper
  URL_WITH_VARIABLE_REGEX = /{{\w+_url}}/

  def ats_sequence_template_make_links_with_variable_unclickable(rich_text)
    return "" if rich_text.body.nil?

    parsed_data = Nokogiri::HTML.parse(rich_text.body.to_html)
    parsed_data.css("a").each do |link|
      link["class"] = "pe-none" if link["href"].match?(URL_WITH_VARIABLE_REGEX)
    end
    sanitize(
      parsed_data.to_html,
      attributes: %w[class href target rel utm_source utm_medium utm_campaign]
    )
  end
end
