# frozen_string_literal: true

class Position < ApplicationRecord
  include Locatable

  acts_as_tenant(:tenant)

  DEFAULT_STAGES = %w[Sourced Contacted Replied Hired].freeze
  LATEST_STAGE_NAME = "Hired"

  CHANGE_STATUS_REASON_LABELS = {
    other: "Other",
    filled: "We filled the position",
    new_position: "New position",
    deprioritized: "The position was deprioritized",
    no_longer_relevant: "No longer relevant",
    cancelled: "We canceled hiring"
  }.freeze

  ACTIVE_REASONS = %i[
    new_position
    other
  ].freeze

  CLOSED_REASONS = %i[
    filled
    no_longer_relevant
    cancelled
    other
  ].freeze

  ON_HOLD_REASONS = %i[
    deprioritized
    other
  ].freeze

  RECRUITER_ACCESS_LEVEL = %w[admin employee].freeze
  COLLABORATORS_ACCESS_LEVEL = %w[admin employee].freeze
  HIRING_MANAGERS_ACCESS_LEVEL = %w[admin employee].freeze
  INTERVIEWERS_ACCESS_LEVEL = %w[admin employee].freeze

  has_and_belongs_to_many :collaborators,
                          class_name: "Member",
                          association_foreign_key: :collaborator_id,
                          join_table: :positions_collaborators

  has_and_belongs_to_many :hiring_managers,
                          class_name: "Member",
                          association_foreign_key: :hiring_manager_id,
                          join_table: :positions_hiring_managers

  has_and_belongs_to_many :interviewers,
                          class_name: "Member",
                          association_foreign_key: :interviewer_id,
                          join_table: :positions_interviewers

  has_many :stages,
           -> { order(:list_index) },
           inverse_of: :position,
           class_name: "PositionStage",
           dependent: :destroy
  has_many :placements, dependent: :destroy
  has_many :events, as: :eventable, dependent: :destroy
  has_many :tasks, as: :taskable, dependent: :destroy
  has_many :sequence_templates, dependent: :nullify

  has_one :added_event,
          -> { where(type: :position_added) },
          class_name: "Event",
          as: :eventable,
          inverse_of: false,
          dependent: nil
  has_one :last_position_status_changed_event,
          -> { where(type: :position_changed, changed_field: :status).order(performed_at: :desc) },
          class_name: "Event",
          as: :eventable,
          inverse_of: false,
          dependent: nil

  belongs_to :location, optional: true
  belongs_to :recruiter, optional: true, class_name: "Member"

  has_rich_text :description

  accepts_nested_attributes_for :stages

  enum status: %i[draft active on_hold closed].index_with(&:to_s)
  enum change_status_reason: %i[
    other
    new_position
    deprioritized
    filled
    no_longer_relevant
    cancelled
  ].index_with(&:to_s)

  strip_attributes collapse_spaces: true, allow_empty: true, only: :name

  validate :location_must_be_city, if: :location_id_changed?

  scope :join_last_placement_added_or_changed_event, lambda {
    joins(
      <<~SQL
        LEFT JOIN events ON events.id = (
          SELECT id
          FROM events
          WHERE events.placement_id = placements.id AND
                (events.type = 'placement_stage_changed' OR
                 events.type = 'placement_added')
          ORDER BY events.performed_at DESC
          LIMIT 1
        )
      SQL
    )
  }

  def self.color_codes_table
    positions = Position.arel_table

    positions
      .project(
        Arel::Nodes::Case
          .new(positions[:status])
          .when("draft").then(-3)
          .when("on_hold").then(3)
          .when("closed").then(6)
          .when("active").then(-1)
          .as("code"),
        positions[:id].as("position_id")
      ).as("color_codes")
  end

  def self.search_by_name(name)
    where("positions.name ILIKE ?", "%#{name}%")
  end

  def self.with_color_codes
    positions = Position.arel_table

    color_codes = color_codes_table

    position_joins =
      positions
      .join(color_codes)
      .on(color_codes[:position_id].eq(positions[:id]))

    select(
      positions[Arel.star],
      color_codes[:code].as("color_code")
    ).joins(position_joins.join_sources)
  end

  def warnings
    @warnings ||= ActiveModel::Errors.new(self)
  end

  def total_placements(recruiter_id: nil)
    result = placements.includes(:candidate)

    recruiter_id.present? ? result.where(candidates: { recruiter_id: }) : result
  end

  def remove
    destroy!
  rescue ActiveRecord::RecordNotDestroyed => e
    errors.add(:base, e.message.to_s)
    false
  end

  private

  def location_must_be_city
    return if location&.type == "city" || location.blank?

    errors.add(:location, "must be city.")
  end
end
