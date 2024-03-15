# frozen_string_literal: true

class CandidateAlternativeName < ApplicationRecord
  belongs_to :candidate

  strip_attributes collapse_spaces: true, only: :name
end
