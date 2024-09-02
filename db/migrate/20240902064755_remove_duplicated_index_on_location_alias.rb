# frozen_string_literal: true

class RemoveDuplicatedIndexOnLocationAlias < ActiveRecord::Migration[7.1]
  def change
    remove_index :location_aliases, column: :location_id
  end
end
