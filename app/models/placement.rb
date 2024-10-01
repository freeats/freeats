# frozen_string_literal: true

class Placement < ApplicationRecord
  acts_as_tenant(:tenant)

  MANUAL_DISQUALIFY_STATUSES =
    %w[availability team_fit remote_only location no_reply not_interested workload other_offer
       overpriced overqualified underqualified position_closed other].freeze
  has_many :events, as: :eventable, dependent: :destroy
  has_many :scorecards, dependent: :destroy
  has_many :sequences, dependent: :destroy

  has_one :added_event,
          -> { where(type: "placement_added") },
          class_name: "Event",
          foreign_key: :eventable_id,
          inverse_of: false,
          dependent: :destroy

  belongs_to :position
  belongs_to :position_stage
  belongs_to :candidate

  enum status: %i[
    qualified
    reserved
    availability
    location
    no_reply
    not_interested
    other_offer
    overpriced
    overqualified
    position_closed
    remote_only
    team_fit
    underqualified
    workload
    other
  ].index_with(&:to_s)

  validate :position_stage_must_be_present_in_position

  scope :join_last_placement_added_or_changed_event, lambda {
    joins(
      <<~SQL
        LEFT JOIN events ON events.id = (
          SELECT id
          FROM events
          WHERE events.eventable_id = placements.id AND
                events.eventable_type = 'Placement' AND
                (events.type = 'placement_changed' OR
                 events.type = 'placement_added')
          ORDER BY events.performed_at DESC
          LIMIT 1
        )
      SQL
    )
  }

  def disqualified?
    %w[qualified reserved].exclude?(status)
  end

  def sourced?
    position_stage.name == "Sourced"
  end

  def hired?
    position_stage.name == "Hired"
  end

  def stage
    position_stage.name
  end

  def stages
    @stages ||= position.stages.pluck(:name)
  end

  def next_stage
    stages[stages.index(stage) + 1] unless stage == stages.last
  end

  def prev_stage
    stages[stages.index(stage) - 1] unless stage == stages.first
  end

  private

  def position_stage_must_be_present_in_position
    return if position.stages.include?(position_stage)

    errors.add(:position_stage, "must be present in position")
  end
end
