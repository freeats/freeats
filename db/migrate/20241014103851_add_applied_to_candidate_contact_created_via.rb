# frozen_string_literal: true

class AddAppliedToCandidateContactCreatedVia < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      ALTER TYPE candidate_contact_created_via ADD VALUE 'applied' AFTER 'api';
    SQL
  end
end
