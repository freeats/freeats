# frozen_string_literal: true

class ScorecardTemplate < ApplicationRecord
  has_many :scorecard_template_questions, dependent: :destroy
  belongs_to :position_stage

  validates :title, presence: true
end
