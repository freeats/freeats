# frozen_string_literal: true

class CreateEmailMessages < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE TYPE public.email_message_sent_via AS ENUM (
            'gmail',
            'internal_sequence',
            'internal_compose',
            'internal_reply'
          );
        SQL
      end
      dir.down do
        execute "DROP TYPE email_message_sent_via;"
      end
    end

    create_table :email_messages do |t|
      t.references :email_thread, foreign_key: true, null: false
      t.column :message_id, :string, null: false, default: ""
      t.column :in_reply_to, :string, null: false, default: ""
      t.column :autoreply_headers, :jsonb, null: false, default: {}
      t.column :timestamp, :integer, null: false
      t.column :subject, :string, null: false, default: ""
      t.column :plain_body, :text, null: false, default: ""
      t.column :html_body, :text, null: false, default: ""
      t.column :plain_mime_type, :string, null: false, default: ""
      t.column :sent_via, :email_message_sent_via, null: true
      t.column :references, :string, array: true, null: false, default: []

      t.timestamps

      t.index :created_at
      t.index :message_id
    end
  end
end
