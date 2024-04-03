# frozen_string_literal: true

class Scorecard < ApplicationRecord
  has_many :scorecard_questions,
           -> { order(:list_index) },
           dependent: :destroy,
           inverse_of: :scorecard
  belongs_to :position_stage
  belongs_to :placement

  has_rich_text :summary

  enum score: %i[
    irrelevant
    relevant
    good
    perfect
  ].index_with(&:to_s)

  validates :title, presence: true
  validates :interviewer, presence: true
  validates :score, presence: true
end
