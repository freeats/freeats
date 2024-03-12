# frozen_string_literal: true

class Candidate < ApplicationRecord
  has_one_attached :avatar do |attachable|
    attachable.variant(:medium, resize_to_fill: [400, 400], preprocessed: true)
  end
end
