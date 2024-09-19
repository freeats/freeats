# frozen_string_literal: true

class AddReferencePositionToLocation < ActiveRecord::Migration[7.1]
  def change
    add_reference :positions, :location, foreign_key: true
  end
end
