# frozen_string_literal: true

class Event < ApplicationRecord
  acts_as_tenant(:tenant)

  TASK_TYPES_FOR_PROFILE_ACTIVITY_TAB = %i[task_added task_changed task_status_changed].freeze

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
  belongs_to :added_watcher,
             class_name: "Member",
             optional: true,
             foreign_key: :changed_to,
             inverse_of: :added_as_watcher_events
  belongs_to :removed_watcher,
             class_name: "Member",
             optional: true,
             foreign_key: :changed_from,
             inverse_of: :removed_as_watcher_events
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
  belongs_to :removed_stage,
             class_name: "PositionStage",
             optional: true,
             foreign_key: :changed_from,
             inverse_of: :removed_event

  enum :type, %i[
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
    placement_removed
    position_added
    position_changed
    position_collaborator_assigned
    position_collaborator_unassigned
    position_hiring_manager_assigned
    position_hiring_manager_unassigned
    position_interviewer_assigned
    position_interviewer_unassigned
    position_recruiter_assigned
    position_recruiter_unassigned
    position_stage_added
    position_stage_changed
    position_stage_removed
    scorecard_added
    scorecard_changed
    scorecard_removed
    scorecard_template_added
    scorecard_template_changed
    scorecard_template_removed
    task_added
    task_changed
    task_status_changed
    task_watcher_added
    task_watcher_removed
  ].index_with(&:to_s)

  self.inheritance_column = nil

  validates_with MergedCandidateIsReadOnlyValidator
  validates :type, presence: true

  after_create :update_candidate_last_activity

  def self.create_changed_event_if_value_changed(
    eventable:,
    changed_field: nil,
    field_type: :singular,
    performed_at: Time.zone.now,
    old_value: nil,
    new_value: nil,
    actor_account: nil,
    properties: {}
  )
    changed_from =
      if field_type == :plural
        (old_value || []).sort
      else
        old_value
      end

    changed_to =
      if field_type == :plural
        (new_value || []).sort
      else
        new_value
      end

    # CV files may have the same names.
    return if changed_from == changed_to && changed_field != "cv"

    class_name = eventable.class.name.downcase
    type = Event.types["#{class_name}_changed"].to_sym

    Event.create!(
      eventable:,
      changed_from:,
      changed_to:,
      changed_field:,
      properties:,
      type:,
      actor_account:,
      performed_at:
    )
  end

  def update_candidate_last_activity
    candidates_to_update =
      if type.in?(%w[placement_added placement_changed])
        [eventable.candidate]
      elsif type == "note_added" && eventable.note_thread.notable.is_a?(Candidate)
        [eventable.note_thread.notable]
      elsif type.in?(%w[scorecard_added scorecard_changed])
        [eventable.placement.candidate]
      elsif type == "active_storage_attachment_added"
        [eventable.record]
      elsif type.in?(%w[email_sent email_received])
        return unless eventable

        eventable.find_candidates_in_message
      elsif eventable.is_a?(Candidate)
        [eventable]
      elsif eventable.is_a?(Task) && eventable.taskable.is_a?(Candidate)
        [eventable.taskable]
      end

    return if candidates_to_update.blank?

    candidates_to_update.each { _1.update_last_activity_at(performed_at, validate: false) }
  end
end
