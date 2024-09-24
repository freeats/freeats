# frozen_string_literal: true

class ScorecardTemplate < ApplicationRecord
  acts_as_tenant(:tenant)

  has_many :events, as: :eventable, dependent: :destroy
  has_many :scorecard_template_questions,
           -> { order(:list_index) },
           dependent: :destroy,
           inverse_of: :scorecard_template
  belongs_to :position_stage

  accepts_nested_attributes_for :scorecard_template_questions
  validates :title, presence: true
end
