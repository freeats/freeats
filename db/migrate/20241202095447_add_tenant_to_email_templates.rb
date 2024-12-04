# frozen_string_literal: true

class AddTenantToEmailTemplates < ActiveRecord::Migration[7.1]
  def change
    add_belongs_to :email_templates, :tenant, index: true, null: false
  end
end
