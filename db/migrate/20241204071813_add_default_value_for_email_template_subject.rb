# frozen_string_literal: true

class AddDefaultValueForEmailTemplateSubject < ActiveRecord::Migration[7.1]
  def change
    change_column_default :email_templates, :subject, from: nil, to: ""
  end
end
