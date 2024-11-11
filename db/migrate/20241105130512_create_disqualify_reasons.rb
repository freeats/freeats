# frozen_string_literal: true

class CreateDisqualifyReasons < ActiveRecord::Migration[7.1]
  def change
    create_table :disqualify_reasons do |t|
      t.string :title, null: false
      t.string :description, null: false, default: ""
      t.belongs_to :tenant, index: false

      t.timestamps
    end

    add_index :disqualify_reasons, %i[tenant_id title], unique: true

    add_reference :placements, :disqualify_reason, foreign_key: true
  end
end
