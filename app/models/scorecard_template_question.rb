# frozen_string_literal: true

class ScorecardTemplateQuestion < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :scorecard_template

  validates :question, presence: true
  validates :list_index, presence: true, numericality: { greater_than: 0 }
end
