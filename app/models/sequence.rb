# frozen_string_literal: true

class Sequence < ApplicationRecord
  has_many :events, as: :eventable, dependent: :destroy
  belongs_to :member_email_address, class_name: "Member::EmailAddress"
  belongs_to :placement
  belongs_to :sequence_template
  belongs_to :email_thread, optional: true

  enum status: %i[running replied exited stopped].index_with(&:to_s)

  validates :to, presence: { message: "Sequence recipient email can't be blank." }
  validates :current_stage, presence: true
  validates :scheduled_at, presence: true
  validates :email_thread_id, uniqueness: true, allow_nil: true
  validate :sequence_must_have_at_least_one_stage
  validate :to_must_be_a_valid_email

  def self.to_stop(email_addresses)
    where(to: email_addresses, status: :running)
  end

  private

  def sequence_must_have_at_least_one_stage
    errors.add(:sequence_template, "is empty.") if sequence_template.stages.empty?
  end

  def to_must_be_a_valid_email
    errors.add(:to, "is invalid email.") unless to.match?(CandidateEmailAddress::EMAIL_REGEXP)
  end
end
