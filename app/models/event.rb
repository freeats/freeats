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
    note_added
    note_removed
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

  after_create :update_candidate_last_activity

  def update_candidate_last_activity
    candidates_to_update =
      if type.in?(%w[sequence_initialized sequence_started sequence_stopped sequence_exited
                     sequence_replied])
        Candidate
          .not_merged
          .search_by_emails(eventable.to)
      elsif type.in?(%w[placement_added placement_changed])
        [eventable.candidate]
      elsif type == "note_added"
        [eventable.note_thread.notable]
      # TODO: implement events where eventable is task
      elsif type.in?(%w[scorecard_added scorecard_updated])
        [eventable.placement.candidate]
      elsif type == "active_storage_attachment_added"
        [eventable.record]
      elsif type.in?(%w[email_sent email_received])
        return unless eventable

        eventable.find_candidates_in_message
      elsif eventable.is_a?(Candidate)
        [eventable]
      end

    return if candidates_to_update.blank?

    candidates_to_update.each { _1.update_last_activity_at(performed_at, validate: false) }
  end
end
