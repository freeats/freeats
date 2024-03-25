# frozen_string_literal: true

class Position < ApplicationRecord
  DEFAULT_STAGES = %w[sourced contacted replied hired].freeze

  has_many :stages,
           -> { order(:list_index) },
           inverse_of: :position,
           class_name: "PositionStage",
           dependent: :destroy

  belongs_to :recruiter, optional: true, class_name: "Member"

  has_rich_text :description

  enum status: %i[draft active passive closed].index_with(&:to_s)
  enum change_status_reason: %i[
    other
    new_position
    deprioritized
    filled
    no_longer_relevant
    cancelled
  ].index_with(&:to_s)

  strip_attributes collapse_spaces: true, allow_empty: true, only: :name
end
