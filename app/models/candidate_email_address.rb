# frozen_string_literal: true

class CandidateEmailAddress < ApplicationRecord
  self.inheritance_column = nil

  EMAIL_REGEXP = %r{\A(?:[\w!#$%&*+\-\/=?^'`{|}~]+\.?)+(?<!\.)@(?:[a-z\d-]+\.)+[a-z]+\z}

  belongs_to :candidate

  enum status: %i[
    current
    invalid
    outdated
  ].index_with(&:to_s), _prefix: true

  enum source: %i[
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
  ].index_with(&:to_s), _prefix: true

  enum type: %i[
    personal
    work
  ].index_with(&:to_s)

  validates :address, presence: true, uniqueness: { scope: :candidate_id }
  validates :list_index, presence: true
  validates :list_index, numericality: { greater_than: 0 }
  validate :address_must_be_valid

  before_validation :normalize_address

  def self.valid_email?(email)
    normalized_email = Normalizer.email_address(email)

    normalized_email =~ EMAIL_REGEXP
  end

  def address_must_be_valid
    return if CandidateEmailAddress.valid_email?(address)

    error_message = "have invalid value"

    candidate.errors.add(:address, error_message)
    errors.add(:address, error_message)
  end

  def normalize_address
    self.address = Normalizer.email_address(address)
  end
end
