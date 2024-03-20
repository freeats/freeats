# frozen_string_literal: true

class Position < ApplicationRecord
  enum status: %i[draft active passive closed].index_with(&:to_s)
  enum change_status_reason: %i[
    other
    new_position
    deprioritized
    filled
    no_longer_relevant
    cancelled
  ].index_with(&:to_s)

  has_rich_text :description
end
