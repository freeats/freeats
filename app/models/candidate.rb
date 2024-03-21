# frozen_string_literal: true

class Candidate < ApplicationRecord
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

  def destroy_file_attachment(attachment)
    transaction do
      AttachmentInformation
        .find_by(active_storage_attachment_id: attachment.id)
        &.destroy

      attachment.purge
    end
  end
end
