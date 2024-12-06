# frozen_string_literal: true

class Account < ApplicationRecord
  include Rodauth::Model(RodauthMain)
  include Avatar

  acts_as_tenant(:tenant)

  has_one :member, dependent: :destroy

  enum :status, unverified: 1, verified: 2, closed: 3

  validates :name, presence: true
  validates :email, presence: true

  before_validation do
    self.linkedin_url = AccountLink.new(linkedin_url).normalize if linkedin_url.present?
  end

  # Needed for Rails Admin to teach how to delete the avatar.
  attr_accessor :remove_avatar

  after_save { avatar.purge if remove_avatar == "1" }

  def rails_admin_name
    email
  end

  def member?
    !member.nil?
  end

  def active_member?
    member? && !member.inactive?
  end

  def cascade_destroy
    member_id = member.id
    Position
      .where(recruiter_id: member_id)
      .find_each do |position|
        position.update!(recruiter_id: nil)
      end

    Scorecard
      .where(interviewer_id: member_id)
      .find_each(&:destroy!)

    Event
      .where(actor_account_id: id)
      .find_each do |event|
        event.update!(actor_account: nil)
      end

    destroy!

    true
  rescue StandardError => e
    errors.add(:base, e)
    false
  end
end
