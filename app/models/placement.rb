# frozen_string_literal: true

class Placement < ApplicationRecord
  acts_as_tenant(:tenant)

  has_many :events, as: :eventable, dependent: :destroy
  has_many :scorecards, dependent: :destroy

  has_one :added_event,
          -> { where(type: "placement_added") },
          class_name: "Event",
          foreign_key: :eventable_id,
          inverse_of: false,
          dependent: nil
  has_one :last_modification_event,
          -> {
            where(type: %w[placement_changed placement_added])
              .order(performed_at: :desc)
          },
          class_name: "Event",
          foreign_key: :eventable_id,
          inverse_of: false,
          dependent: nil

  belongs_to :position
  belongs_to :position_stage
  belongs_to :candidate
  belongs_to :disqualify_reason, optional: true

  enum :status, %i[
    qualified
    reserved
    disqualified
  ].index_with(&:to_s)

  validate :position_stage_must_be_present_in_position
  validate :only_disqualified_placements_have_disqualify_reason

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

  def only_disqualified_placements_have_disqualify_reason
    if status == "disqualified" && disqualify_reason.blank?
      errors.add(:base, "Disqualified placement must have a disqualification reason")
    elsif status != "disqualified" && disqualify_reason.present?
      errors.add(:base, "Not disqualified placement must not have a disqualification reason")
    end
  end
end
