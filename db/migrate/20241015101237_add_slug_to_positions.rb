# frozen_string_literal: true

class AddSlugToPositions < ActiveRecord::Migration[7.1]
  def change
    add_column :positions, :slug, :string
    add_index :positions, :slug, unique: true
  end
end
