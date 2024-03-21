# frozen_string_literal: true

class CreateMembers < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE TYPE member_access_level AS
            ENUM ('inactive', 'interviewer', 'employee', 'hiring_manager', 'admin');
        SQL
      end
      dir.down do
        execute "DROP TYPE member_access_level;"
      end
    end

    create_table :members do |t|
      t.references :account, null: false, foreign_key: true
      t.column :access_level, :member_access_level, null: false

      t.timestamps
    end
  end
end
