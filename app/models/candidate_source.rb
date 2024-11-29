# frozen_string_literal: true

class CandidateSource < ApplicationRecord
  acts_as_tenant(:tenant)

  has_many :candidates, dependent: :nullify
  # belongs_to :tenant

  strip_attributes collapse_spaces: true, allow_empty: true, only: :name

  validates :name, presence: true
  # validates :name, uniqueness: true
end
