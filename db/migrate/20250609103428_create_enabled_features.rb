# frozen_string_literal: true

class CreateEnabledFeatures < ActiveRecord::Migration[7.1]
  def change
    create_enum :feature_name, %w[
      emails
    ]

    create_table :enabled_features do |t|
      t.belongs_to :tenant, null: false, foreign_key: true
      t.enum(:name, enum_type: :feature_name, null: false)

      t.timestamps
    end

    add_index :enabled_features, %i[tenant_id name], unique: true
  end
end
