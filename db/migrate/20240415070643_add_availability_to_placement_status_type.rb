# frozen_string_literal: true

class AddAvailabilityToPlacementStatusType < ActiveRecord::Migration[7.1]
  def up
    execute "ALTER TYPE placement_status ADD VALUE 'availability' BEFORE 'location';"
  end
end
