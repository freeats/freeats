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
  belongs_to :stage_from,
             class_name: "PositionStage",
             optional: true,
             foreign_key: :changed_from,
             inverse_of: :moved_from_events
  belongs_to :stage_to,
             class_name: "PositionStage",
             optional: true,
             foreign_key: :changed_to,
             inverse_of: :moved_to_events

  enum type: %i[
    active_storage_attachment_added
    active_storage_attachment_removed
    candidate_added
    candidate_changed
    candidate_merged
    candidate_recruiter_assigned
    candidate_recruiter_unassigned
    email_received
    email_sent
    placement_added
    placement_changed
    position_added
    position_changed
    position_recruiter_assigned
    position_recruiter_unassigned
    position_stage_added
    position_stage_changed
    scorecard_added
    scorecard_template_added
    scorecard_template_updated
    scorecard_updated
    sequence_exited
    sequence_initialized
    sequence_replied
    sequence_resumed
    sequence_started
    sequence_stopped
  ].index_with(&:to_s)

  self.inheritance_column = nil

  validates :type, presence: true
  validates :eventable_type, presence: true
  validates :eventable_id, presence: true # rubocop:disable Rails/RedundantPresenceValidationOnBelongsTo
end
