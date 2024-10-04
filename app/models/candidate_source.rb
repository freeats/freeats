# frozen_string_literal: true

class CandidateSource < ApplicationRecord
  acts_as_tenant(:tenant)

  has_many :candidates, dependent: :nullify

  strip_attributes collapse_spaces: true, allow_empty: true, only: :name

  validates :name, presence: true
  # validates :name, uniqueness: true

  def self.search_by_name(name)
    where("lower(f_unaccent(name)) LIKE lower(f_unaccent(?))", "%#{name}%")
  end
end
