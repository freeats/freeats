# frozen_string_literal: true

class AddReferenceCandidateLocationToLocationTable < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :candidates, :locations
  end
end
