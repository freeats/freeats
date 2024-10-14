# frozen_string_literal: true

class AddCareerSiteFunctionalColumnsToTenants < ActiveRecord::Migration[7.1]
  def change
    add_column :tenants, :career_site_enabled, :boolean, default: false, null: false
    add_column :tenants, :domain, :string, null: false, default: ""
    add_column :tenants, :subdomain, :string, null: false, default: ""
    add_column :tenants, :public_styles, :text, null: false, default: ""

    add_index :tenants, :domain, unique: true, where: "domain != ''"
    add_index :tenants, :subdomain, unique: true, where: "subdomain != ''"
  end
end
