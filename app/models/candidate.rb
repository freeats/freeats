# frozen_string_literal: true

class Candidate < ApplicationRecord
  include Dry::Monads[:result]
  include Locatable
  include Avatar
  acts_as_tenant(:tenant)

  has_many :placements, dependent: :destroy
  has_many :candidate_links,
           class_name: "CandidateLink",
           dependent: :destroy,
           inverse_of: :candidate
  has_many :candidate_alternative_names,
           -> { order(:name) },
           class_name: "CandidateAlternativeName",
           dependent: :destroy,
           inverse_of: :candidate
  has_many :candidate_email_addresses,
           -> { order(:list_index) },
           class_name: "CandidateEmailAddress",
           dependent: :destroy,
           inverse_of: :candidate,
           foreign_key: :candidate_id
  has_many :candidate_phones,
           -> { order(:list_index) },
           class_name: "CandidatePhone",
           dependent: :destroy,
           inverse_of: :candidate,
           foreign_key: :candidate_id
  has_many :note_threads, as: :notable, dependent: :destroy
  has_many :events, as: :eventable, dependent: :destroy
  has_many :tasks, as: :taskable, dependent: :destroy
  has_one :added_event,
          -> { where(type: :candidate_added) },
          class_name: "Event",
          as: :eventable,
          inverse_of: false,
          dependent: nil

  belongs_to :candidate_source, optional: true
  belongs_to :location, optional: true
  belongs_to :recruiter, optional: true, class_name: "Member"

  accepts_nested_attributes_for :candidate_email_addresses, allow_destroy: true
  accepts_nested_attributes_for :candidate_phones, allow_destroy: true
  accepts_nested_attributes_for :candidate_links, allow_destroy: true
  accepts_nested_attributes_for :candidate_alternative_names, allow_destroy: true

  has_many_attached :files
  has_rich_text :cover_letter

  strip_attributes collapse_spaces: true, allow_empty: true, only: :full_name

  validates :full_name, presence: true

  scope :with_emails, lambda { |emails|
    not_merged
      .left_outer_joins(:candidate_email_addresses)
      .where(
        <<~SQL,
          candidate_email_addresses.address IN
          (SELECT unnest(array[?]::citext[]))
        SQL
        emails
      )
  }

  scope :not_merged, -> { where(merged_to: nil) }

  def self.search_by_names_or_emails(name_or_email)
    name_or_email = name_or_email.strip

    # Regex for consecutive Unicode alphabetic and digit characters (3 or more).
    return none unless name_or_email.match?(/[[:alpha:]\d]{3,}/)

    if name_or_email.include?("@")
      normalized_email = Normalizer.email_address(name_or_email)
      return search_by_emails(normalized_email)
    end

    names =
      if name_or_email.match?(/^(".+?")( OR ".+?")?$/)
        name_or_email.scan(/"(.+?)"/).flatten.grep(/[[:alpha:]\d]{3,}/)
      else
        ["%#{name_or_email}%"]
      end

    query_variable = "lower(f_unaccent(?))"
    like_query =
      if names.size > 1
        query_variables = names.map { query_variable }.join(", ")
        "LIKE ANY (array[#{query_variables}])"
      else
        "LIKE #{query_variable}"
      end

    not_merged.left_joins(:candidate_alternative_names)
              .where("lower(f_unaccent(candidates.full_name)) #{like_query}", *names)
              .or(
                where("lower(f_unaccent(candidate_alternative_names.name)) #{like_query}", *names)
              )
  end

  def self.search_by_emails(email)
    emails_array = Array(email).map(&:strip)
    not_merged
      .joins(:candidate_email_addresses)
      .where("candidate_email_addresses.address = ANY (ARRAY[?])", emails_array)
  end

  def self.duplicates_by_emails_links_and_phones(emails:, links:, phones:)
    join_same_addresses_and_links_query = <<~SQL
      JOIN (
        SELECT
          candidates.id,
          array_agg(intersection.same_addresses) AS same_addresses,
          array_agg(intersection.same_links) AS same_links,
          array_agg(intersection.same_phones) AS same_phones
        FROM candidates
        JOIN (
          SELECT
            candidates.id,
            candidate_email_addresses.address AS same_addresses,
            NULL AS same_links,
            NULL AS same_phones
          FROM candidates
          LEFT JOIN candidate_email_addresses ON candidate_email_addresses.candidate_id = candidates.id
          WHERE candidate_email_addresses.address IN (SELECT unnest(array[:addresses]::citext[]))
            AND status != 'invalid'

          UNION

          SELECT
            candidates.id,
            NULL AS same_addresses,
            candidate_links.url as same_links,
            NULL AS same_phones
          FROM candidates
          LEFT JOIN candidate_links ON candidate_links.candidate_id = candidates.id
          WHERE candidate_links.url IN (SELECT unnest(array[:links]::varchar[]))

          UNION

          SELECT
            candidates.id,
            NULL AS same_addresses,
            NULL AS same_links,
            candidate_phones.phone AS same_phones
          FROM candidates
          LEFT JOIN candidate_phones ON candidate_phones.candidate_id = candidates.id
          WHERE candidate_phones.phone IN (SELECT unnest(array[:phones]::varchar[]))
            AND status != 'invalid'
            AND (type IS NULL OR type = 'personal')
        ) AS intersection ON candidates.id = intersection.id
        GROUP BY candidates.id
      ) AS candidates_with_intersections ON candidates.id = candidates_with_intersections.id
    SQL

    select(
      "candidates.*",
      "candidates_with_intersections.same_addresses",
      "candidates_with_intersections.same_links",
      "candidates_with_intersections.same_phones"
    )
      .joins(
        sanitize_sql_for_conditions(
          [
            join_same_addresses_and_links_query,
            { addresses: emails,
              links:,
              phones: }
          ]
        )
      )
  end

  def remove
    destroy!
  rescue ActiveRecord::RecordNotDestroyed => e
    errors.add(:base, e.message.to_s)
    false
  end

  def candidate_emails
    candidate_email_addresses.pluck(:address)
  end

  def names
    [full_name, *candidate_alternative_names.pluck(:name)]
  end

  def encoded_names
    names.map { "\"#{URI.encode_www_form_component(_1)}\"" }
  end

  def github_search_url
    search_string = names.map { "fullname:\"#{_1}\"" }.join(" ")
    "https://github.com/search?utf8=%E2%9C%93&q=#{CGI.escape(search_string)}" \
      "&type=Users&ref=advsearch&l=&l="
  end

  def google_search_url
    google_query =
      [*names, *candidate_email_addresses.pluck(:address)]
      .filter(&:present?).map { |p| "\"#{p}\"" }.join(" OR ")
    "https://www.google.com/search?q=#{URI.encode_www_form_component(google_query)}"
  end

  def facebook_search_url
    "https://www.facebook.com/search/people/?q=#{encoded_names.join(' OR ')}"
  end

  def linkedin_search_url
    "https://www.linkedin.com/search/results/people/?keywords=#{encoded_names.join(' OR ')}"
  end

  def sorted_links(status: nil)
    domains = AccountLink::DOMAINS
    social_links = []
    other_links = []
    links_array = links(status:)
    links_array.each do |link|
      if domains[link]
        index = domains.values.find_index { |k, _| k == domains[link] }
        social_links << [index, link]
      else
        other_links << link
      end
    end
    social_links.sort!.each(&:shift).flatten!
    [social_links, other_links]
  end

  def sorted_candidate_links
    domains = AccountLink::DOMAINS
    sorted_links = candidate_links.to_a
    sorted_links&.sort_by do |link|
      domain_index =
        if domains[link.url] && (link.status == "current")
          domains.values.find_index { |k, _| domains[link.url] == k }
        else
          Float::INFINITY
        end
      [domain_index, link.status == "current" ? 0 : 1]
    end
  end

  def cover_letter_template
    return if cover_letter.present?

    <<~HTML
      <div>
        <i>HEADLINE with NUMBER years of experience</i>
        <br>
        Tech:
        <br>
        Location: Helsinki, Finland
        <br>
        English:
        <br>
        Salary expectations:
        <br><br>
        <b>Current job</b>
        <br><br>
        <i>TITLE at COMPANY for the last NUMBER years</i>
        <br>
        Skill:
        <br>
        Working on:
        <br><br>
        <b>Job change</b>
        <br><br>
        Not looking to change job actively
        <br>
        Notice period:
        <br><br>
        <b>Notes</b>
        <br>
      </div>
    HTML
  end

  def source
    candidate_source&.name
  end

  def source=(source_name)
    self.candidate_source =
      if source_name.present?
        CandidateSource.find_by("lower(f_unaccent(name)) = lower(f_unaccent(?))", source_name)
      end
  end

  def links(status: nil)
    status = { status: } if status
    candidate_links.where(status).pluck(:url).uniq
  end

  def links=(new_links)
    new_candidate_links =
      new_links
      .filter { _1[:url].present? }
      .uniq { _1[:url] }

    existing_candidate_links =
      candidate_links.where(
        url: new_candidate_links.map { _1[:url] }
      ).to_a

    transaction do
      result_candidate_links = []
      new_candidate_links.each do |link_attributes|
        existing_link = existing_candidate_links.find { _1.url == link_attributes[:url] }
        if existing_link
          existing_link.update!(link_attributes)
          result_candidate_links << existing_link
        else
          result_candidate_links <<
            CandidateLink.new(
              link_attributes.merge(candidate: self)
            )
        end
      end

      self.candidate_links = result_candidate_links
    end
  end

  def phones(status: nil)
    status = { status: } if status
    candidate_phones.where(status).pluck(:phone).uniq
  end

  def phones=(new_phones)
    status_priority = %w[current outdated invalid].freeze
    new_candidate_phones = new_phones.sort_by { status_priority.index(_1[:status]) }
                                     .filter { _1[:phone].present? }
                                     .uniq { _1[:phone] }

    existing_candidate_phones =
      candidate_phones.where(
        phone: new_candidate_phones.map { _1[:phone] }
      ).to_a

    transaction do
      result_candidate_phones = []
      new_candidate_phones.each.with_index(1) do |phone_attributes, index|
        existing_phone_number =
          existing_candidate_phones
          .find { _1.phone == phone_attributes[:phone] }
        if existing_phone_number
          phone_attributes[:list_index] = index if existing_phone_number.list_index != index
          existing_phone_number.update!(phone_attributes)
          result_candidate_phones << existing_phone_number
        else
          result_candidate_phones <<
            CandidatePhone.new(
              phone_attributes.merge(
                list_index: index,
                candidate: self
              )
            )
        end
      end
      self.candidate_phones = result_candidate_phones
    end
  end

  def emails(status: nil)
    status = { status: } if status
    candidate_email_addresses.where(status).pluck(:address).uniq
  end

  def emails=(new_email_addresses)
    new_candidate_email_addresses = CandidateEmailAddress.combine(
      old_email_addresses: candidate_email_addresses.to_a,
      new_email_addresses:,
      candidate_id: id
    )
    self.candidate_email_addresses = new_candidate_email_addresses
  end

  def cv
    files
      .attachments
      .joins(:attachment_information)
      .find_by(attachment_information: { is_cv: true })
  end

  def all_files
    files.joins(:blob).order(id: :desc)
  end

  def duplicates_for_merge_dialog
    not_merged_duplicates
      .unscope(:select)
      .select(
        "candidates.id",
        "candidates.full_name",
        "candidates.recruiter_id",
        "candidates_with_intersections.same_addresses",
        "candidates_with_intersections.same_links",
        "candidates_with_intersections.same_phones"
      ).to_a
  end

  def not_merged_duplicates
    duplicates.where(merged_to: nil)
  end

  def merged_duplicates
    merged_duplicates_sql = <<~SQL
      WITH RECURSIVE t(id) AS (
        SELECT id FROM candidates WHERE merged_to = ?
        UNION
        SELECT candidates.id FROM candidates, t WHERE merged_to = t.id
      )
      SELECT t.id FROM t;
    SQL
    merged_duplicate_ids = self.class.find_by_sql(
      self.class.sanitize_sql_for_conditions([merged_duplicates_sql, id])
    ).map(&:id)
    self.class.where(id: merged_duplicate_ids)
  end

  def duplicates
    self
      .class
      .duplicates_by_emails_links_and_phones(
        emails: all_emails(status: %i[current outdated]),
        links: sorted_links.first,
        phones: all_phones(status: %i[current outdated], type: [:personal, nil])
      )
      .where.not(id:)
  end

  def all_emails(status: nil, type: nil)
    status = { status: } if status
    type = { type: } if type
    candidate_email_addresses
      .where(status)
      .where(type)
      .order(:list_index)
      .pluck(:address)
      .uniq
  end

  def all_phones(status: nil, type: nil)
    status = { status: } if status
    type = { type: } if type
    candidate_phones
      .where(status)
      .where(type)
      .order(:list_index)
      .pluck(:phone)
      .uniq
  end

  def url
    Rails.application.routes.url_helpers.tab_ats_candidate_url(
      self,
      tab: :info,
      host: ENV.fetch("HOST_URL", nil),
      protocol: ATS::Application.config.force_ssl ? "https" : "http"
    )
  end

  def synchronize_email_messages(addresses = [], now: false, queue: :sync_emails)
    return if queue == :scraping_processing

    addresses_to_sync = addresses.presence || all_emails

    Member.with_linked_email_service.pluck(:id).each do |member_id|
      if now
        SynchronizeEmailMessagesForEmailJob.set(queue:).perform_now(member_id, addresses_to_sync)
      else
        SynchronizeEmailMessagesForEmailJob.set(queue:).perform_later(member_id, addresses_to_sync)
      end
    end
  end

  def update_last_activity_at(date, validate: true)
    self.last_activity_at = date if last_activity_at.before?(date)

    validate ? save! : save(validate:)
  end

  def positions_for_quick_assignment(current_member_id)
    Position
      .where(status: %w[draft open])
      .where(
        <<~SQL,
          (positions.recruiter_id = :current_member_id
            OR EXISTS (
            SELECT 1
            FROM positions_collaborators
            WHERE positions_collaborators.position_id = positions.id
            AND positions_collaborators.collaborator_id = :current_member_id
            )
          )
          AND NOT EXISTS (
            SELECT 1
            FROM placements
            WHERE candidate_id = :id
            AND position_id = positions.id
          )
        SQL
        current_member_id:, id:
      )
  end

  def scorecards
    Scorecard
      .where(
        <<~SQL,
          EXISTS (
            SELECT 1
            FROM placements
            WHERE placements.candidate_id = :candidate_id
            AND scorecards.placement_id = placements.id
          )
        SQL
        candidate_id: id
      )
  end
end
