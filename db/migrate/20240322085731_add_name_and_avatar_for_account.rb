# frozen_string_literal: true

class AddNameAndAvatarForAccount < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :name, :string, null: false
  end
end
