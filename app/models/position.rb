# frozen_string_literal: true

class Position < ApplicationRecord
  DEFAULT_STAGES = %w[sourced contacted replied hired].freeze

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

  PASSIVE_REASONS = %i[
    deprioritized
    other
  ].freeze

  has_and_belongs_to_many :collaborators,
                          class_name: "Member",
                          association_foreign_key: :collaborator_id,
                          join_table: :positions_collaborators

  has_many :stages,
           -> { order(:list_index) },
           inverse_of: :position,
           class_name: "PositionStage",
           dependent: :destroy

  belongs_to :recruiter, optional: true, class_name: "Member"

  has_rich_text :description

  accepts_nested_attributes_for :stages

  enum status: %i[draft active passive closed].index_with(&:to_s)
  enum change_status_reason: %i[
    other
    new_position
    deprioritized
    filled
    no_longer_relevant
    cancelled
  ].index_with(&:to_s)

  strip_attributes collapse_spaces: true, allow_empty: true, only: :name

  def self.color_codes_table
    positions = Position.arel_table

    positions
      .project(
        Arel::Nodes::Case
          .new(positions[:status])
          .when("draft").then(-3)
          .when("passive").then(3)
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
end
