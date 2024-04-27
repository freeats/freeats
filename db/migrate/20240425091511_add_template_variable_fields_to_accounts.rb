# frozen_string_literal: true

class AddTemplateVariableFieldsToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :linkedin_url, :string, null: false, default: ""
    add_column :accounts, :calendar_url, :string, null: false, default: ""
    add_column :accounts, :female, :boolean, null: false, default: false
  end
end
