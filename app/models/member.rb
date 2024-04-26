# frozen_string_literal: true

class Member < ApplicationRecord
  has_and_belongs_to_many :reacted_notes,
                          class_name: "Note",
                          join_table: :note_reactions
  has_and_belongs_to_many :note_threads
  has_and_belongs_to_many :collaborator_positions,
                          class_name: "Position",
                          foreign_key: :collaborator_id,
                          join_table: :positions_collaborators
  has_and_belongs_to_many :hiring_positions,
                          class_name: "Position",
                          foreign_key: :hiring_manager_id,
                          join_table: :positions_hiring_managers
  has_and_belongs_to_many :interviewer_positions,
                          class_name: "Position",
                          foreign_key: :interviewer_id,
                          join_table: :positions_interviewers
  has_many :positions,
           inverse_of: :recruiter,
           foreign_key: :recruiter_id,
           dependent: :restrict_with_exception
  has_many :email_addresses, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :assigned_events,
           lambda { where(type: %i[position_recruiter_assigned candidate_recruiter_assigned]) },
           class_name: "Event",
           inverse_of: :assigned_member,
           dependent: :destroy
  has_many :unassigned_events,
           lambda { where(type: %i[position_recruiter_unassigned candidate_recruiter_unassigned]) },
           class_name: "Event",
           inverse_of: :unassigned_member,
           dependent: :destroy

  belongs_to :account

  enum access_level: %i[inactive interviewer hiring_manager employee admin].index_with(&:to_s)

  validates :access_level, presence: true

  default_scope { includes(:account) }
  scope :active, -> { where.not(access_level: :inactive) }
  scope :rails_admin_search, ->(query) { joins(:account).where(accounts: { email: query.strip }) }

  scope :mentioned_in, lambda { |text|
    joins(:account).where(accounts: { name: text.scan(/\B@(\p{L}+\s\p{L}+)/).flatten })
  }
  scope :with_email, lambda {
    active.includes(user: :identities).where(users: { identities: { provider: "toughbyte" } })
  }

  def self.find_by_address(address)
    left_joins(:account, :email_addresses)
      .where(account: { email: address })
      .or(
        where(email_addresses: { address: })
      )
      .first
  end

  def self.imap_accounts
    includes(:email_addresses)
      .where.not(email_addresses: { refresh_token: "" })
      .map(&:email_addresses)
      .flatten
      .map(&:imap_account)
  end

  def active?
    !inactive?
  end

  def deactivate
    transaction do
      update!(access_level: :inactive)
      account.identities.destroy_all
    end
  end

  def rails_admin_name
    "#{account&.email}|#{access_level}"
  end

  def name
    account.name
  end

  def reacted_to_note?(note)
    reacted_notes.find { _1.id == note.id }
  end

  def any_email_service_linked?
    email_addresses.where.not(refresh_token: "").exists?
  end
end
