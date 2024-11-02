# frozen_string_literal: true

class AddNotNullToTenantIdInAllTables < ActiveRecord::Migration[7.1]
  def change
    change_column_null(:positions, :tenant_id, false)
    change_column_null(:scorecards, :tenant_id, false)
    change_column_null(:events, :tenant_id, false)
    change_column_null(:email_threads, :tenant_id, false)
    change_column_null(:candidate_email_addresses, :tenant_id, false)
    change_column_null(:candidate_links, :tenant_id, false)
    change_column_null(:candidate_sources, :tenant_id, false)
    change_column_null(:email_messages, :tenant_id, false)
    change_column_null(:accounts, :tenant_id, false)
    change_column_null(:email_message_addresses, :tenant_id, false)
    change_column_null(:placements, :tenant_id, false)
    change_column_null(:scorecard_questions, :tenant_id, false)
    change_column_null(:scorecard_template_questions, :tenant_id, false)
    change_column_null(:tasks, :tenant_id, false)
    change_column_null(:scorecard_templates, :tenant_id, false)
    change_column_null(:note_threads, :tenant_id, false)
    change_column_null(:notes, :tenant_id, false)
    change_column_null(:position_stages, :tenant_id, false)
    # access_tokens table already has this constraint
    change_column_null(:candidate_phones, :tenant_id, false)
    change_column_null(:members, :tenant_id, false)
    change_column_null(:candidate_alternative_names, :tenant_id, false)
    change_column_null(:candidates, :tenant_id, false)
  end
end
