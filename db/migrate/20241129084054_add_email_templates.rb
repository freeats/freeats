# frozen_string_literal: true

class AddEmailTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :email_templates do |t|
      t.string :name, null: false
      t.string :subject, null: false
      t.timestamps

      t.index :name, unique: true
    end
  end
end
