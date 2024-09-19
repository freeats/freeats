# frozen_string_literal: true

class AddIndexesToEventsTable < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :events,
              %i[type performed_at],
              order: { performed_at: :desc },
              algorithm: :concurrently
    add_index :events, :properties, using: :gin, algorithm: :concurrently
    add_index :events,
              :changed_field,
              where: "changed_field IS NOT NULL",
              algorithm: :concurrently
    add_index :events, :changed_from, using: :gin, algorithm: :concurrently
    add_index :events, :changed_to, using: :gin, algorithm: :concurrently
  end
end
