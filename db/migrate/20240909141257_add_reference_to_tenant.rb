# frozen_string_literal: true

class AddReferenceToTenant < ActiveRecord::Migration[7.1]
  def change
    add_belongs_to :accounts, :tenant, index: true
    add_belongs_to :candidates, :tenant, index: true
    add_belongs_to :candidate_alternative_names, :tenant, index: true
    add_belongs_to :candidate_email_addresses, :tenant, index: true
    add_belongs_to :candidate_links, :tenant, index: true
    add_belongs_to :candidate_phones, :tenant, index: true
    add_belongs_to :candidate_sources, :tenant, index: true
    add_belongs_to :email_message_addresses, :tenant, index: true
    add_belongs_to :email_messages, :tenant, index: true
    add_belongs_to :email_threads, :tenant, index: true
    add_belongs_to :events, :tenant, index: true
    add_belongs_to :member_email_addresses, :tenant, index: true
    add_belongs_to :members, :tenant, index: true
    add_belongs_to :note_threads, :tenant, index: true
    add_belongs_to :notes, :tenant, index: true
    add_belongs_to :placements, :tenant, index: true
    add_belongs_to :position_stages, :tenant, index: true
    add_belongs_to :positions, :tenant, index: true
    add_belongs_to :scorecard_questions, :tenant, index: true
    add_belongs_to :scorecard_template_questions, :tenant, index: true
    add_belongs_to :scorecard_templates, :tenant, index: true
    add_belongs_to :scorecards, :tenant, index: true
    add_belongs_to :sequence_template_stages, :tenant, index: true
    add_belongs_to :sequence_templates, :tenant, index: true
    add_belongs_to :sequences, :tenant, index: true
    add_belongs_to :tasks, :tenant, index: true
  end
end
