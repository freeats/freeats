# frozen_string_literal: true

class MoveMemberEmailAddressesColumnsToMembers < ActiveRecord::Migration[7.1]
  def change
    add_column :members, :refresh_token, :string, null: false, default: ""
    add_column :members, :token, :string, null: false, default: ""
    add_column :members, :last_email_synchronization_uid, :int

    remove_reference :sequences, :member_email_address
    add_reference :sequences, :member, null: false, foreign_key: true

    drop_table :member_email_addresses do |t|
      t.references :member, null: false, foreign_key: true
      t.citext :address, null: false
      t.string :token, null: false, default: ""
      t.string :refresh_token, null: false, default: ""
      t.integer :last_email_synchronization_uid

      t.timestamps
    end
  end
end
