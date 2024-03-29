# frozen_string_literal: true

class RemoveIndexFromCandidateEmailAddresses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      DROP INDEX CONCURRENTLY index_candidate_email_addresses_on_candidate_id_and_list_index;
    SQL
  end

  def down
    execute <<~SQL
      CREATE UNIQUE INDEX CONCURRENTLY index_candidate_email_addresses_on_candidate_id_and_list_index
        ON candidate_email_addresses USING btree (candidate_id, list_index);;
    SQL
  end
end
