# frozen_string_literal: true

class AddMissingFieldsToCandidate < ActiveRecord::Migration[7.1]
  def change
    remove_column :candidates, :resume_updated_at, :timestamp

    rename_column :candidates, :dont_contant, :blacklisted

    add_column :candidates, :headline, :string, null: false, default: ""
    add_column :candidates, :telegram, :string, null: false, default: ""
    add_column :candidates, :skype, :string, null: false, default: ""
  end
end
