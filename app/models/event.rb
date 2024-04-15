# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :actor_account, class_name: "Account", optional: true
  belongs_to :eventable, polymorphic: true
  belongs_to :assigned_member,
             class_name: "Member",
             optional: true,
             foreign_key: :changed_to,
             inverse_of: :assigned_events
  belongs_to :unassigned_member,
             class_name: "Member",
             optional: true,
             foreign_key: :changed_from,
             inverse_of: :unassigned_events

  enum type: %i[
    candidate_added
    candidate_changed
    candidate_merged
    candidate_recruiter_assigned
    candidate_recruiter_unassigned
    position_added
    position_changed
    position_recruiter_assigned
    position_recruiter_unassigned
    position_stage_added
    position_stage_changed
    scorecard_template_added
    scorecard_template_updated
  ].index_with(&:to_s)

  self.inheritance_column = nil

  validates :type, presence: true
  validates :eventable_type, presence: true
  validates :eventable_id, presence: true # rubocop:disable Rails/RedundantPresenceValidationOnBelongsTo
end
