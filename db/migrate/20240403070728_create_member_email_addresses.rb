# frozen_string_literal: true

class CreateMemberEmailAddresses < ActiveRecord::Migration[7.1]
  def change
    create_table :member_email_addresses do |t|
      t.references :member, null: false, foreign_key: true
      t.citext :address, null: false
      t.string :token, null: false, default: ""
      t.string :refresh_token, null: false, default: ""
      t.integer :last_email_synchronization_uid

      t.timestamps
    end
  end
end
