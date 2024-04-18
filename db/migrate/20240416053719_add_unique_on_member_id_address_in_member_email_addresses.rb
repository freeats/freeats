# frozen_string_literal: true

class AddUniqueOnMemberIdAddressInMemberEmailAddresses < ActiveRecord::Migration[7.1]
  def change
    add_index :member_email_addresses, :address, unique: true
  end
end
