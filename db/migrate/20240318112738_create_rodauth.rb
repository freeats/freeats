# frozen_string_literal: true

class CreateRodauth < ActiveRecord::Migration[7.1]
  def change
    enable_extension "citext"

    create_table :accounts do |t|
      t.integer :status, null: false, default: 1
      t.citext :email, null: false
      t.index :email, unique: true, where: "status IN (1, 2)"
    end

    # Used by the remember me feature
    create_table :account_remember_keys, id: false do |t|
      t.bigint :id, primary_key: true
      t.foreign_key :accounts, column: :id
      t.string :key, null: false
      t.datetime :deadline, null: false
    end
  end
end
