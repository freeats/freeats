# frozen_string_literal: true

class DisqualifyReason < ApplicationRecord
  acts_as_tenant(:tenant)

  MANDATORY_REASONS = ["No reply", "Position closed"].freeze

  has_many :placements, dependent: :restrict_with_exception

  validates :title,
            presence: true,
            uniqueness: { scope: :tenant_id, conditions: -> { where(deleted: false) } }
  validates :list_index, uniqueness: { scope: :tenant_id, conditions: -> { where(deleted: false) } }

  scope :not_deleted, -> { where(deleted: false) }
  scope :deleted, -> { where(deleted: true) }
end
