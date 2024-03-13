# frozen_string_literal: true

class LocationHierarchy < ApplicationRecord
  belongs_to :parent_location, optional: true, class_name: "Location"
  belongs_to :location

  validates :path, presence: true
  validates :path, uniqueness: true
end
