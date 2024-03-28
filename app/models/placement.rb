# frozen_string_literal: true

class Placement < ApplicationRecord
  has_many :scorecards, dependent: :restrict_with_exception
  belongs_to :position
  belongs_to :position_stage
  belongs_to :candidate

  enum status: %i[
    qualified
    reserved
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

  private

  def position_stage_must_be_present_in_position
    return if position.stages.include?(position_stage)

    errors.add(:position_stage, "must be present in position")
  end
end
