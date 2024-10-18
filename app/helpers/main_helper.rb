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

  def event_actor_account_name_for_assignment(event:, member:)
    if event.actor_account&.member == member
      "themselves"
    else
      tag.b(member.name)
    end
  end
end
