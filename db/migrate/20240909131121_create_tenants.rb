# frozen_string_literal: true

class CreateTenants < ActiveRecord::Migration[7.1]
  def change
    create_enum :tenant_locale, %i[en ru]

    create_table :tenants do |t|
      t.string :name, null: false
      t.column :locale, :tenant_locale, null: false

      t.timestamps
    end
  end
end
