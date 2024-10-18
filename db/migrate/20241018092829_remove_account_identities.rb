# frozen_string_literal: true

class RemoveAccountIdentities < ActiveRecord::Migration[7.1]
  def change
    drop_table :account_identities do |t|
      t.references :account, foreign_key: { on_delete: :cascade }
      t.string :provider, null: false
      t.string :uid, null: false
      t.index %i[provider uid], unique: true
    end
  end
end
