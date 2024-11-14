# frozen_string_literal: true

class EmailMessage < ApplicationRecord
  acts_as_tenant(:tenant)

  MAIL_SERVICE_ADDRESSES = %w[
    mailer-daemon@googlemail.com
    mailer-daemon@yahoo.com
    mailer-daemon@kapsi.fi
    notifications@gitflow.com
    notification@slack.com
    notifications@mixmax.com
    postmaster@outlook.com
    noreply@clickup.com
    noreply@hh.ru
    noreply@calamari.io
    noreply@github.com
  ].freeze
  DAEMON_USERNAMES = %w[
    mailer-daemon
    postmaster
    postmester
    microsoftexchange
  ].freeze

  has_many :email_message_addresses, dependent: :destroy
  has_many :events, as: :eventable, dependent: :destroy

  belongs_to :email_thread

  enum :sent_via, %i[gmail internal_compose internal_reply].index_with(&:to_s)

  validates :timestamp, presence: true

  scope :with_addresses, lambda {
    email_messages = EmailMessage.arel_table
    email_message_addresses = EmailMessageAddress.arel_table

    select(
      email_messages[Arel.star],
      ARRAY_UNIQUE_ADDRESSES_SQL.call("from_addresses"),
      ARRAY_UNIQUE_ADDRESSES_SQL.call("to_addresses"),
      ARRAY_UNIQUE_ADDRESSES_SQL.call("cc_addresses"),
      ARRAY_UNIQUE_ADDRESSES_SQL.call("bcc_addresses")
    )
      .joins(
        email_messages
          .join(
            email_message_addresses
              .project(
                Arel.sql("coalesce(array_agg((name, address) ORDER BY position) " \
                         "FILTER (WHERE field = 'from'), '{}')")
                    .as("from_addresses"),
                Arel.sql("coalesce(array_agg((name, address) ORDER BY position) " \
                         "FILTER (WHERE field = 'to'), '{}')")
                    .as("to_addresses"),
                Arel.sql("coalesce(array_agg((name, address) ORDER BY position) " \
                         "FILTER (WHERE field = 'cc'), '{}')")
                    .as("cc_addresses"),
                Arel.sql("coalesce(array_agg((name, address) ORDER BY position) " \
                         "FILTER (WHERE field = 'bcc'), '{}')")
                    .as("bcc_addresses")
              )
              .where(email_message_addresses[:email_message_id].eq(email_messages[:id]))
              .group(email_message_addresses[:email_message_id])
              .lateral
              .as("ema")
          )
          .on(Arel::Nodes::True.new)
          .join_sources
      )
  }

  ARRAY_UNIQUE_ADDRESSES_SQL = lambda { |arr_field|
    "coalesce((SELECT array_agg(DISTINCT ARRAY[t.name, t.address]) FROM " \
      "unnest(ema.#{arr_field}) t(name varchar, address citext)), '{}'::varchar[]) " \
      "AS #{arr_field}"
  }
  private_constant :ARRAY_UNIQUE_ADDRESSES_SQL
  def self.arel_join_address_sql(email_addresses:, field: nil)
    email_message_addresses = EmailMessageAddress.arel_table

    # Following `join` is used to filter email messages instead of direct `where`
    # clause because `where` clause would also filter out the results.
    relevant_email_addresses = Arel::Table.new(:relevant_email_addresses)
    join_relevant_addresses =
      email_message_addresses
      .where(
        email_message_addresses[:address].in(email_addresses)
      )
      .where(field ? email_message_addresses[:field].eq(field) : Arel::Nodes::True.new)
      .project(email_message_addresses[:email_message_id].as("relevant_email_address"))
      .as("relevant_email_addresses")

    join_email_message =
      email_message_addresses
      .project(
        :email_message_id,
        Arel.sql("coalesce(array_agg((name, address) ORDER BY position) " \
                 "FILTER (WHERE field = 'from'), '{}')")
            .as("from_addresses"),
        Arel.sql("coalesce(array_agg((name, address) ORDER BY position) " \
                 "FILTER (WHERE field = 'to'), '{}')")
            .as("to_addresses"),
        Arel.sql("coalesce(array_agg((name, address) ORDER BY position) " \
                 "FILTER (WHERE field = 'cc'), '{}')")
            .as("cc_addresses"),
        Arel.sql("coalesce(array_agg((name, address) ORDER BY position) " \
                 "FILTER (WHERE field = 'bcc'), '{}')")
            .as("bcc_addresses")
      )
      .join(join_relevant_addresses)
      .on(relevant_email_addresses[:relevant_email_address]
            .eq(email_message_addresses[:email_message_id]))
      .group(email_message_addresses[:email_message_id])
      .as("ema")

    email_messages = EmailMessage.arel_table
    email_messages.join(join_email_message)
                  .on(email_messages[:id].eq(join_email_message[:email_message_id]))
  end

  def self.messages_with_addresses(with:)
    select(
      "email_messages.*",
      ARRAY_UNIQUE_ADDRESSES_SQL.call("from_addresses"),
      ARRAY_UNIQUE_ADDRESSES_SQL.call("to_addresses"),
      ARRAY_UNIQUE_ADDRESSES_SQL.call("cc_addresses"),
      ARRAY_UNIQUE_ADDRESSES_SQL.call("bcc_addresses")
    ).joins(
      arel_join_address_sql(email_addresses: Array(with)).join_sources
    )
  end

  def self.messages_from_addresses(from:)
    select(
      "email_messages.*",
      ARRAY_UNIQUE_ADDRESSES_SQL.call("from_addresses"),
      ARRAY_UNIQUE_ADDRESSES_SQL.call("to_addresses"),
      ARRAY_UNIQUE_ADDRESSES_SQL.call("cc_addresses"),
      ARRAY_UNIQUE_ADDRESSES_SQL.call("bcc_addresses")
    ).joins(
      arel_join_address_sql(email_addresses: Array(from), field: "from").join_sources
    )
  end

  def self.messages_to_addresses(to:)
    select(
      "email_messages.*",
      ARRAY_UNIQUE_ADDRESSES_SQL.call("from_addresses"),
      ARRAY_UNIQUE_ADDRESSES_SQL.call("to_addresses"),
      ARRAY_UNIQUE_ADDRESSES_SQL.call("cc_addresses"),
      ARRAY_UNIQUE_ADDRESSES_SQL.call("bcc_addresses")
    ).joins(
      arel_join_address_sql(email_addresses: Array(to), field: "to").join_sources
    )
  end

  def sender_avatar_url(hashed_avatars, sender_emails)
    if hashed_avatars.key?(sender_emails.first)
      hashed_avatars[sender_emails.first]
    else
      candidate =
        Candidate
        .joins(:candidate_email_addresses)
        .find_by(
          merged_to: nil,
          candidate_email_addresses: { address: sender_emails.first }
        )

      hashed_avatars[sender_emails.first] = candidate.avatar.variant(:medium) if candidate.present?
    end

    hashed_avatars[sender_emails.first]
  end

  def sanitized_body(hide_quote: true)
    if html_body.present?
      doc = Nokogiri::HTML(html_body)
      doc.search("img").each do |node|
        if node["src"]&.match?(/^http/)
          node.add_class("img-fluid")
        else
          node.replace(
            %(<img alt="[x]" title="Embedded images not supported" />)
          )
        end
      end
      doc.search("script").each(&:remove)
      doc.search("style").each(&:remove)

      # Insert ellipsis for folding previous replies and hiding them.
      if hide_quote && (quote = doc.at_css(".gmail_quote") || doc.at_css("blockquote"))
        if quote.attr("class") == "gmail_quote"
          quote.add_class("hidden")
        else
          doc.search("blockquote").each do |node|
            node.add_class("hidden")

            # Remove display settings in node styles.
            if node.attributes["style"].present? # rubocop:disable Style/Next
              style_value = node.attributes["style"].value
              node.attributes["style"].value = style_value.sub(/display: ?.*?;/, "")
                                                          .sub(/display: ?.*;?/, "")
            end
          end
        end
        ellipsis = Nokogiri::HTML.fragment(%(<img alt="..." title="Expand blockquote" />))
        quote.add_previous_sibling(ellipsis)
      end

      # Conclude single list items into list.
      doc.search("li").each do |node|
        node.replace("<ul>#{node}</ul>") if %w[ul ol].exclude?(node.parent.name)
      end

      ActionController::Base.helpers.sanitize(
        doc.to_s,
        tags: %w[br p a div span style blockquote img table tbody tr th td colgroup col center i
                 ul ol li strong em],
        attributes: %w[href style scoped type alt src class colspan rawspan width height dir align
                       clear cellpadding title]
      )
    elsif plain_body.present? && plain_mime_type == "text/plain"
      ActionController::Base.helpers.simple_format(plain_body)
    end
  end

  def date
    Time.zone.at(timestamp)
  end

  def grouped_addresses
    @grouped_addresses ||= email_message_addresses.group_by(&:field)
  end

  def fetch_from_addresses
    @fetch_from_addresses ||= grouped_addresses["from"]&.pluck(:address) || []
  end

  def fetch_to_addresses
    @fetch_to_addresses ||= grouped_addresses["to"]&.pluck(:address) || []
  end

  def fetch_cc_addresses
    @fetch_cc_addresses ||= grouped_addresses["cc"]&.pluck(:address) || []
  end

  def fetch_bcc_addresses
    @fetch_bcc_addresses ||= grouped_addresses["bcc"]&.pluck(:address) || []
  end

  def define_addresses_getters
    define_singleton_method(:from_addresses) do
      grouped_addresses["from"]&.pluck(:name, :address) || []
    end
    define_singleton_method(:to_addresses) do
      grouped_addresses["to"]&.pluck(:name, :address) || []
    end
    define_singleton_method(:cc_addresses) do
      grouped_addresses["cc"]&.pluck(:name, :address) || []
    end
    define_singleton_method(:bcc_addresses) do
      grouped_addresses["bcc"]&.pluck(:name, :address) || []
    end
    self
  end

  def present_emails
    fetch_from_addresses + fetch_to_addresses + fetch_cc_addresses + fetch_bcc_addresses
  end

  def find_parent
    self.class.find_by(message_id: [in_reply_to, references.last].compact_blank)
  end

  def find_candidates_in_message
    Candidate.with_emails([fetch_from_addresses.first] + fetch_to_addresses)
  end

  def candidates_in_thread
    @candidates_in_thread ||=
      begin
        thread_emails = email_thread.email_message_addresses.pluck(:address)
        Candidate.with_emails(thread_emails)
      end
  end

  def url(object_id, controller_name)
    path_params = {
      id: object_id,
      tab: "emails",
      host: ENV.fetch("HOST_URL", "localhost:3000"),
      protocol: ATS::Application.config.force_ssl ? "https" : "http",
      email_message_id: id
    }
    case controller_name
    when "candidates"
      Rails.application.routes.url_helpers.tab_ats_candidate_url(**path_params)
    else
      raise NotImplementedError, "Unsupported model"
    end
  end
end
