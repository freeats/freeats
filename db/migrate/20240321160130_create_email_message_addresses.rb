# frozen_string_literal: true

class CreateEmailMessageAddresses < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE TYPE public.email_message_field AS ENUM (
              'from',
              'to',
              'cc',
              'bcc'
          );
        SQL
      end

      dir.down do
        execute "DROP TYPE email_message_field;"
      end
    end

    create_table :email_message_addresses do |t|
      t.references :email_message
      t.column :address, :citext, null: false
      t.column :field, :email_message_field, null: false
      t.column :position, :integer, null: false
      t.column :name, :string, null: false, default: ""

      t.timestamps
      t.index :address
    end
  end
end
