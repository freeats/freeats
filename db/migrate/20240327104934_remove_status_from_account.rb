# frozen_string_literal: true

class RemoveStatusFromAccount < ActiveRecord::Migration[7.1]
  def change
    remove_column :accounts, :status
    add_index :accounts, :email, unique: true
  end
end
