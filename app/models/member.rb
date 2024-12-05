# frozen_string_literal: true

class Member < ApplicationRecord
  acts_as_tenant(:tenant)

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
  has_and_belongs_to_many :watched_tasks,
                          class_name: "Task",
                          join_table: :tasks_watchers,
                          foreign_key: :watcher_id
  has_many :positions,
           inverse_of: :recruiter,
           foreign_key: :recruiter_id,
           dependent: :restrict_with_exception
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
  has_many :added_as_watcher_events,
           lambda { where(type: :task_watcher_added) },
           class_name: "Event",
           inverse_of: :added_watcher,
           dependent: :destroy
  has_many :removed_as_watcher_events,
           lambda { where(type: :task_watcher_removed) },
           class_name: "Event",
           inverse_of: :removed_watcher,
           dependent: :destroy
  has_many :tasks,
           inverse_of: :assignee,
           foreign_key: :assignee_id,
           dependent: :destroy
  has_many :scorecards,
           foreign_key: :interviewer_id,
           inverse_of: :interviewer,
           dependent: :restrict_with_exception
  has_many :candidate_email_addresses,
           class_name: "CandidateEmailAddress",
           inverse_of: :created_by,
           foreign_key: :created_by_id,
           dependent: :nullify
  has_many :candidate_phones,
           class_name: "CandidatePhone",
           inverse_of: :created_by,
           foreign_key: :created_by_id,
           dependent: :nullify
  has_many :candidate_links,
           class_name: "CandidateLink",
           inverse_of: :created_by,
           foreign_key: :created_by_id,
           dependent: :nullify

  belongs_to :account

  enum :access_level, %i[inactive member admin].index_with(&:to_s)

  validates :access_level, presence: true

  default_scope { includes(:account) }
  scope :active, -> { where.not(access_level: :inactive) }
  scope :rails_admin_search, ->(query) { joins(:account).where(accounts: { email: query.strip }) }

  scope :mentioned_in, lambda { |text|
    longest_mentions = text.scan(/\B@((?:\p{L}+\s?)+)/).flatten
    names = []
    longest_mentions.each do |mention|
      mention_parts = mention.split
      mention_parts.each_index do |index|
        names << mention_parts[0..index].join(" ")
      end
    end

    joins(:account).where(accounts: { name: names })
  }
  scope :with_linked_email_service, -> {
    where.not(refresh_token: "")
  }

  def self.find_by_address(address)
    joins(:account).find_by(account: { email: address })
  end

  def self.imap_accounts
    with_linked_email_service.map(&:imap_account)
  end

  # Imap accounts are mutated during request, changes should be persisted back to database.
  def self.postprocess_imap_account(imap_account, update_imap_uid: true)
    if !imap_account.status.in?(%i[succeeded network_issues])
      find_by_address(imap_account.email)
        .reset_email_service_tokens
      imap_account.logger.warn(status: imap_account.status, method: "postprocess_imap_account")
    elsif update_imap_uid
      find_by_address(imap_account.email)
        .update!(last_email_synchronization_uid: imap_account.last_message_uid)
    end
  end

  def self.email_addresses(except: nil)
    active.where.not(id: except&.id).map(&:email_address)
  end

  def imap_account
    Imap::Account.new(
      email: email_address,
      access_token: token,
      refresh_token:,
      last_email_synchronization_uid:
    )
  end

  def active?
    !inactive?
  end

  def deactivate
    transaction do
      update!(access_level: :inactive)
    end
  end

  def reactivate
    update!(access_level: :member)
  end

  def rails_admin_name
    "#{account&.email}|#{access_level}"
  end

  def name
    account.name
  end

  def email_address
    account.email
  end

  def reacted_to_note?(note)
    reacted_notes.find { _1.id == note.id }
  end

  def email_service_linked?
    refresh_token.present?
  end

  def reset_email_service_tokens
    update!(token: "", refresh_token: "")
  end

  def tasks_count
    Task.pending_for(self).size
  end
end
