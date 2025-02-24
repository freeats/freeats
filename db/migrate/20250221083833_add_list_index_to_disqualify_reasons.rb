# frozen_string_literal: true

class AddListIndexToDisqualifyReasons < ActiveRecord::Migration[7.1]
  def change
    add_column :disqualify_reasons, :list_index, :integer
    add_column :disqualify_reasons, :deleted, :boolean, default: false, null: false

    # Fill in list_index for existing disqualify reasons using SQL
    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE disqualify_reasons
          SET list_index = subquery.new_index
          FROM (
            SELECT id, ROW_NUMBER() OVER (PARTITION BY tenant_id ORDER BY title) AS new_index
            FROM disqualify_reasons
            WHERE deleted = false
          ) AS subquery
          WHERE disqualify_reasons.id = subquery.id;
        SQL
      end
    end

    change_column_null :disqualify_reasons, :list_index, false

    remove_index :disqualify_reasons, %i[tenant_id title] if index_exists?(:disqualify_reasons, %i[tenant_id title])

    # Add a partial index to enforce uniqueness only when deleted is false
    add_index :disqualify_reasons, %i[tenant_id list_index], unique: true, where: "deleted = false"
    add_index :disqualify_reasons, %i[tenant_id title], unique: true, where: "deleted = false"
  end
end
