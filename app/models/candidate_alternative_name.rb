# frozen_string_literal: true

class CandidateAlternativeName < ApplicationRecord
  belongs_to :candidate

  strip_attributes collapse_spaces: true, allow_empty: true, only: :name
end
