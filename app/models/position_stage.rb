# frozen_string_literal: true

class PositionStage < ApplicationRecord
  belongs_to :position

  before_save :update_list_index_for_hired_stage

  validates :name, uniqueness: { scope: :position_id }

  private

  def update_list_index_for_hired_stage
    position_stages = position.stages.to_a

    # Remove the old self, it detects object with the same id
    position_stages.delete(self)
    position_stages << self

    hired_position_stage = position_stages.find { _1.name == "hired" }

    return if hired_position_stage.blank?

    max_existing_list_index = position_stages.map(&:list_index).max

    position_stages_with_max_list_index = position_stages.filter do |position_stage|
      position_stage.list_index == max_existing_list_index
    end

    return if position_stages_with_max_list_index == [hired_position_stage]

    hired_position_stage.update!(list_index: max_existing_list_index + 1)
  end
end
