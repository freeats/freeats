# frozen_string_literal: true

class RemoveFieldsOnTenants < ActiveRecord::Migration[7.1]
  def change
    remove_column :tenants, :domain
    remove_column :tenants, :subdomain
  end
end
