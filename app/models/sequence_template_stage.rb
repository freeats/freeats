# frozen_string_literal: true

class SequenceTemplateStage < ApplicationRecord
  belongs_to :sequence_template

  has_rich_text :body

  validates :position, numericality: { greater_than_or_equal_to: 1 }
  validates :body, presence: { message: "can't be blank, remove empty stages or add text." }
end
