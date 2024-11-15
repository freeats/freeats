# frozen_string_literal: true

class EmailMessageAddress < ApplicationRecord
  include EmailRegexp

  acts_as_tenant(:tenant)

  belongs_to :email_message

  enum :field, %i[from to cc bcc].index_with(&:to_s), suffix: true

  validates :address, presence: true
  validates :address, format: { with: EMAIL_REGEXP }
  validates :position, presence: true
  validates :position, numericality: { greater_than: 0 }
  validates :field, presence: true

  before_validation :normalize_address

  def normalize_address
    self.address = Normalizer.email_address(address)
  end
end
