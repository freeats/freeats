# frozen_string_literal: true

class ScorecardTemplateQuestion < ApplicationRecord
  belongs_to :scorecard_template

  validates :question, presence: true
  validates :list_index, presence: true
end
