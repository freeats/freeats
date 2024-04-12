# frozen_string_literal: true

module MainHelper
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
end
