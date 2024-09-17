# frozen_string_literal: true

module MainHelper
  EMAIL_TEMPLATE_VARIABLES =
    YAML.safe_load(
      Rails.root.join("config/email_templates/email_template_variables.yml").read
    )

  def plain_format(text, html_options = {}, options = {})
    simple_format(
      Rinku.auto_link(
        text.strip.gsub(/\r?\n/, "<br>"),
        :all,
        'target="_blank" rel="noopener noreferrer"'
      ),
      html_options,
      options
    )
  end

  # By default use plain_format unless specified otherwise in business requirements.
  def preformatted_plain_format(text, member_links: false)
    tag.div(style: "white-space: pre-wrap;") do
      sanitize(
        Note.public_send(
          member_links ? :mark_mentions_with_member_links : :mark_mentions,
          Rinku.auto_link(
            h(text),
            :all,
            'target="_blank" rel="noopener"'
          )
        ),
        tags: %w[a span],
        attributes: %w[href target rel class]
      )
    end
  end

  def email_templates_variables_help_for(type)
    variables =
      case type
      when "position_sequence_template"
        LiquidTemplate::SEQUENCE_TEMPLATE_VARIABLE_NAMES
      end

    template_variables = EMAIL_TEMPLATE_VARIABLES.filter { _1.in?(variables) }
    sorted_template_variables = template_variables.sort_by { |k, _v| k }.to_h

    formatted_variables =
      safe_join(
        [
          tag.ul(class: "list-group list-group-flush") do
            safe_join(
              sorted_template_variables.map do |name, description|
                tag.li(class: "list-group-item px-0 pb-0 border-bottom-0") do
                  "{{#{name}}} - #{description}"
                end
              end
            )
          end
        ]
      )

    safe_join(
      [
        tag.h2("Template variables", class: "mb-0"),
        formatted_variables
      ]
    )
  end
end
