# frozen_string_literal: true

class CandidateEmailAddress < ApplicationRecord
  include EmailRegexp

  acts_as_tenant(:tenant)

  self.inheritance_column = nil

  belongs_to :candidate
  belongs_to :created_by, class_name: "Member", optional: true

  enum :status, %i[
    current
    invalid
    outdated
  ].index_with(&:to_s), prefix: true

  enum :source, %i[
    bitbucket
    devto
    djinni
    github
    habr
    headhunter
    hunter
    indeed
    kendo
    linkedin
    nymeria
    salesql
    other
  ].index_with(&:to_s), prefix: true

  enum :type, %i[
    personal
    work
  ].index_with(&:to_s)

  enum :created_via, %i[
    api
    applied
    manual
  ].index_with(&:to_s), prefix: true

  validates :address, presence: true, uniqueness: { scope: :candidate_id }
  validates :list_index, presence: true
  validates :list_index, numericality: { greater_than: 0 }
  validate :address_must_be_valid

  before_validation :normalize_address

  def self.valid_email?(email)
    normalized_email = Normalizer.email_address(email)

    normalized_email =~ EMAIL_REGEXP
  end

  def self.combine(old_email_addresses:, new_email_addresses:, candidate_id:)
    status_priority = %w[current outdated invalid].freeze

    new_emails =
      new_email_addresses.dup.each { _1[:address] = Normalizer.email_address(_1[:address]) }
    new_emails = new_emails.sort_by { status_priority.index(_1[:status]) }
    new_emails = new_emails.filter { _1[:address].present? }.uniq { _1[:address] }

    new_candidate_email_addresses = []

    new_emails.each.with_index(1) do |attributes, index|
      attributes[:created_via] ||= "manual"

      existing_email_address =
        old_email_addresses
        .find do |email_address|
          email_address.address == attributes[:address]
        end

      if existing_email_address
        attributes[:list_index] = index

        if existing_email_address.created_via == attributes[:created_via]
          attributes[:created_by] = existing_email_address.created_by
          attributes[:added_at] = existing_email_address.added_at
        end

        existing_email_address.assign_attributes(attributes)
        new_candidate_email_addresses << existing_email_address
      else
        new_candidate_email_addresses <<
          new(
            attributes.merge(
              list_index: index,
              candidate_id:
            )
          )
      end
    end

    new_candidate_email_addresses
  end

  def address_must_be_valid
    return if CandidateEmailAddress.valid_email?(address)

    error_message = "have invalid value: #{address}"

    candidate.errors.add(:address, error_message)
    errors.add(:address, error_message)
  end

  def normalize_address
    self.address = Normalizer.email_address(address)
  end

  def to_params
    attributes.symbolize_keys.slice(
      :address,
      :list_index,
      :status,
      :type,
      :source,
      :url,
      :added_at,
      :created_by_id,
      :created_via
    )
  end
end
