# frozen_string_literal: true

class CreateAttachmentInformation < ActiveRecord::Migration[7.1]
  def change
    create_table :attachment_informations do |t|
      t.boolean :is_cv
      t.references :active_storage_attachment, null: false, foreign_key: true

      t.timestamps
    end
  end
end
