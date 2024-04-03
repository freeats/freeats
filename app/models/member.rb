# frozen_string_literal: true

class Member < ApplicationRecord
  has_and_belongs_to_many :collaborator_positions,
                          class_name: "Position",
                          foreign_key: :collaborator_id,
                          join_table: :positions_collaborators
  has_many :positions,
           inverse_of: :recruiter,
           foreign_key: :recruiter_id,
           dependent: :restrict_with_exception
  has_many :member_email_addresses, dependent: :destroy

  belongs_to :account

  enum access_level: %i[inactive interviewer hiring_manager employee admin].index_with(&:to_s)

  validates :access_level, presence: true

  scope :active, -> { where.not(access_level: :inactive) }
  scope :rails_admin_search, ->(query) { joins(:account).where(accounts: { email: query.strip }) }

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
end
