# frozen_string_literal: true

class Candidate < ApplicationRecord
  include Dry::Monads[:result]
  include Locatable

  has_many :candidate_links,
           class_name: "CandidateLink",
           dependent: :destroy,
           inverse_of: :candidate
  has_many :candidate_alternative_names,
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
  belongs_to :candidate_source, optional: true
  belongs_to :location, optional: true

  accepts_nested_attributes_for :candidate_email_addresses, allow_destroy: true
  accepts_nested_attributes_for :candidate_phones, allow_destroy: true
  accepts_nested_attributes_for :candidate_links, allow_destroy: true

  has_one_attached :avatar do |attachable|
    attachable.variant(:icon, resize_to_fill: [144, 144], preprocessed: true)
    attachable.variant(:medium, resize_to_fill: [450, 450], preprocessed: true)
  end

  has_many_attached :files
  has_rich_text :cover_letter

  strip_attributes collapse_spaces: true, allow_empty: true, only: :full_name

  validates :full_name, presence: true

  scope :with_emails, lambda { |emails|
    not_merged
      .left_outer_joins(:email_addresses)
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

  def candidate_emails
    candidate_email_addresses.pluck(:address)
  end

  def attach_avatar(avatar_file)
    jpg_avatar = ImageProcessing::Vips.source(avatar_file).convert!("jpg")
    original_filename = avatar_file.original_filename
    filename = File.basename(original_filename, File.extname(original_filename))
    avatar.attach(io: jpg_avatar, filename: "#{filename}.jpg")
  end

  def destroy_avatar
    avatar.purge
  end

  def destroy_file(file_id)
    file = files.find(file_id)

    transaction do
      file.attachment_information&.destroy!
      file.purge
    end
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

  def gmail_search_url
    "https://mail.google.com/mail/u/0/#search/#{encoded_names.join(' OR ')}"
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

  def vk_search_url
    query = names.join("%20")
    "https://vk.com/search/people?q=#{query}"
  end

  def change(params)
    case Candidates::Change.new(candidate: self, params: params.to_h).call
    in Success()
      reload
      true
    in Failure("record_invalid")
      false
    end
  end

  def sorted_links
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
    candidate_email_addresses.where(status).pluck(:url).uniq
  end

  def emails=(new_email_addresses)
    # @old_emails = emails

    new_candidate_email_addresses = CandidateEmailAddress.combine(
      old_email_addresses: candidate_email_addresses.to_a,
      new_email_addresses:,
      candidate_id: id
    )
    # email_addresses_for_removal =
    #   @old_emails.map { CandidateEmailAddress.trimmed_address(_1) } -
    #   new_candidate_email_addresses.map { CandidateEmailAddress.trimmed_address(_1.address) }
    self.candidate_email_addresses = new_candidate_email_addresses

    # TODO: adapt and uncomment.
    # remove_orphaned_email_messages(email_addresses_for_removal)
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
end
