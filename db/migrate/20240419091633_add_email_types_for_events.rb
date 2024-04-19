# frozen_string_literal: true

class AddEmailTypesForEvents < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'email_sent';
      ALTER TYPE event_type ADD VALUE 'email_received';
    SQL
  end
end
