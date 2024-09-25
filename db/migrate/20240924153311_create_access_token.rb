# frozen_string_literal: true

class CreateAccessToken < ActiveRecord::Migration[7.1]
  def up
    create_table :access_tokens do |t|
      t.binary :hashed_token, null: false, index: false
      t.citext :sent_to, null: false, index: true
      t.datetime :sent_at
      t.column :context, :access_token_context, null: false
      t.references :tenant, null: false, foreign_key: true, index: true

      t.timestamps
    end

    execute <<-SQL
      CREATE INDEX index_access_tokens_on_hashed_token
      ON access_tokens
      USING hash (hashed_token);
    SQL
  end

  def down
    drop_table :access_tokens
  end
end
