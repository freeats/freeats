# frozen_string_literal: true

class DisqualifyReason < ApplicationRecord
  acts_as_tenant(:tenant)

  has_many :placements, dependent: :restrict_with_exception

  validates :title, presence: true, uniqueness: { scope: :tenant_id }
end
