# frozen_string_literal: true

class LocationAlias < ApplicationRecord
  belongs_to :location

  validates :alias, presence: true
end
