# frozen_string_literal: true

class AddUniqIndexOnCandidateSourcesForTenantIdAndName < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE UNIQUE INDEX CONCURRENTLY index_candidate_sources_on_tenant_id_and_name
        ON candidate_sources USING btree (tenant_id, name);;
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX CONCURRENTLY index_candidate_sources_on_tenant_id_and_name;
    SQL
  end
end
