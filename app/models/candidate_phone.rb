# frozen_string_literal: true

class CandidatePhone < ApplicationRecord
  self.inheritance_column = nil

  # Numbers in E164 format.
  BLACKLISTED_PHONES = [
    "+46706240058"
  ].freeze

  belongs_to :candidate

  enum type: %i[
    personal
    work
  ].index_with(&:to_s)
  enum source: %i[
    bitbucket
    devto
    djinni
    github
    habr
    headhunter
    indeed
    kendo
    linkedin
    nymeria
    salesql
    other
  ].index_with(&:to_s), _prefix: true
  enum status: %i[
    current
    invalid
    outdated
  ].index_with(&:to_s), _prefix: true

  validates :list_index, presence: true
  validates :list_index, numericality: { greater_than: 0 }
  validates :phone, presence: true, uniqueness: { scope: :candidate_id }
  validate :phone_must_be_valid

  before_save do
    code = candidate&.location&.country_code || "RU"
    self.phone = CandidatePhone.normalize(phone, code)
  end

  def self.normalize(phone, country_code)
    if Phonelib.valid_for_country?(phone, country_code)
      Phonelib.parse(phone, country_code).e164
    else
      Phonelib.parse(phone).e164
    end
  end

  def self.blacklisted_phone?(phone)
    CandidatePhone::BLACKLISTED_PHONES.include?(phone)
  end

  def self.valid_phone?(phone, country_code = "RU")
    country_code ||= "RU"
    parsed_phone = Phonelib.parse(phone, country_code).e164
    return false if blacklisted_phone?(parsed_phone)

    Phonelib.possible?(phone) || Phonelib.valid_for_country?(phone, country_code)
  end

  def self.international_phone(phone)
    normalized_phone = Phonelib::Phone.new(phone)
    if normalized_phone.valid?
      Phonelib.parse(phone).international
    else
      phone
    end
  end

  private

  def phone_must_be_valid
    return if CandidatePhone.valid_phone?(phone, candidate&.location&.country_code)

    error_message = "have invalid or contain blacklisted value: #{phone}"

    candidate.errors.add(:phone, error_message)
    errors.add(:phone, error_message)
  end
end
