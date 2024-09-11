# frozen_string_literal: true

class ScorecardQuestion < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :scorecard

  validates :question, presence: true
  validates :list_index, presence: true

  has_rich_text :answer
end
