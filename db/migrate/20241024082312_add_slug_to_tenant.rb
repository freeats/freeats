# frozen_string_literal: true

class AddSlugToTenant < ActiveRecord::Migration[7.1]
  def change
    add_column :tenants, :slug, :string, null: false, default: ""

    add_index :tenants, :slug, unique: true, where: "slug != ''"
  end
end
