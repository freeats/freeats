# frozen_string_literal: true

class AddEmailTemplateIndexOnTenantAndName < ActiveRecord::Migration[7.1]
  def change
    remove_index :email_templates, column: :name
    remove_index :email_templates, column: :tenant_id
    add_index :email_templates, %i[tenant_id name], unique: true
  end
end
