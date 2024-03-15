# frozen_string_literal: true

class CreateEmailThreads < ActiveRecord::Migration[7.1]
  def change
    create_table(:email_threads, &:timestamps)
  end
end
