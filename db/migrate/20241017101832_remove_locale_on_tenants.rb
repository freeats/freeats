# frozen_string_literal: true

class RemoveLocaleOnTenants < ActiveRecord::Migration[7.1]
  def change
    remove_column :tenants, :locale

    drop_enum(:tenant_locale, if_exists: true)
  end
end
