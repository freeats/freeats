# frozen_string_literal: true

class CandidateSource < ApplicationRecord
  has_many :candidates, dependent: :nullify

  strip_attributes collapse_spaces: true, allow_empty: true, only: :name

  validates :name, presence: true
  validates :name, uniqueness: true
end
