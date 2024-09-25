# frozen_string_literal: true

class PositionStage < ApplicationRecord
  acts_as_tenant(:tenant)

  has_many :scorecards, dependent: :destroy
  has_many :moved_to_events,
           lambda { where(type: :placement_changed, changed_field: :stage) },
           class_name: "Event",
           inverse_of: :stage_to,
           dependent: :destroy
  has_many :moved_from_events,
           lambda { where(type: :placement_changed, changed_field: :stage) },
           class_name: "Event",
           inverse_of: :stage_from,
           dependent: :destroy
  has_many :placements, dependent: :destroy
  has_one :scorecard_template, dependent: :destroy
  belongs_to :position

  before_save :update_list_index_for_hired_stage

  accepts_nested_attributes_for :scorecard_template, allow_destroy: true

  validates :name, uniqueness: { scope: :position_id }

  scope :not_deleted, -> { where(deleted: false) }

  private

  def update_list_index_for_hired_stage
    position_stages = position.stages.to_a

    # Remove the old self, it detects object with the same id
    position_stages.delete(self)
    position_stages << self

    hired_position_stage = position_stages.find { _1.name == Position::LATEST_STAGE_NAME }

    return if hired_position_stage.blank?

    max_existing_list_index = position_stages.map(&:list_index).max

    position_stages_with_max_list_index = position_stages.filter do |position_stage|
      position_stage.list_index == max_existing_list_index
    end

    return if position_stages_with_max_list_index == [hired_position_stage]

    hired_position_stage.update!(list_index: max_existing_list_index + 1)
  end
end
