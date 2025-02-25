# frozen_string_literal: true

class AddTransactionalEmailSentToEvents < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'transactional_email_sent';
    SQL
  end
end
