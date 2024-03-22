# frozen_string_literal: true

class Candidate < ApplicationRecord
  include Dry::Monads[:result]
  include Locatable

  has_many :links,
           class_name: "CandidateLink",
           dependent: :destroy,
           inverse_of: :candidate
  has_many :alternative_names,
           class_name: "CandidateAlternativeName",
           dependent: :destroy,
           inverse_of: :candidate
  has_many :email_addresses,
           -> { order(:list_index) },
           class_name: "CandidateEmailAddress",
           dependent: :destroy,
           inverse_of: :candidate,
           foreign_key: :candidate_id
  has_many :phones,
           -> { order(:list_index) },
           class_name: "CandidatePhone",
           dependent: :destroy,
           inverse_of: :candidate,
           foreign_key: :candidate_id
  belongs_to :candidate_source, optional: true
  belongs_to :location, optional: true

  has_one_attached :avatar do |attachable|
    attachable.variant(:icon, resize_to_fill: [144, 144], preprocessed: true)
    attachable.variant(:medium, resize_to_fill: [450, 450], preprocessed: true)
  end

  has_many_attached :files

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

    not_merged.left_joins(:alternative_names)
              .where("lower(f_unaccent(candidates.full_name)) #{like_query}", *names)
              .or(
                where("lower(f_unaccent(candidate_alternative_names.name)) #{like_query}", *names)
              )
  end

  def self.search_by_emails(email)
    emails_array = Array(email).map(&:strip)
    not_merged
      .joins(:email_addresses)
      .where("candidate_email_addresses.address = ANY (ARRAY[?])", emails_array)
  end

  def candidate_emails
    email_addresses.pluck(:address)
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

  def destroy_file_attachment(attachment)
    transaction do
      AttachmentInformation
        .find_by(active_storage_attachment_id: attachment.id)
        &.destroy

      attachment.purge
    end
  end

  def names
    [full_name, *alternative_names.pluck(:name)]
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
      [*names, *email_addresses.pluck(:address)]
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
      true
    in Failure("record_invalid")
      false
    end
  end

  def sorted_links
    domains = AccountLink::DOMAINS
    sorted_links = links.to_a
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
end
