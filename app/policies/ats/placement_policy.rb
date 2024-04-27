# frozen_string_literal: true

class ATS::PlacementPolicy < ApplicationPolicy
  alias_rule :change_stage?, to: :change_status?

  def change_status?
    available_for_employee? ||
      (position_hiring_manager? && !record.stage.in?(%w[Sourced Contacted]))
  end

  def destroy?
    (available_for_admin? || placement_creator?) &&
      record.stage == "Sourced" && record.scorecards.blank?
    # TODO: After implementing sequences.
    # && record.sequences.blank?
  end

  private

  def placement_creator?
    record.added_event.actor_account.member.id == member.id
  end

  def position_hiring_manager?
    available_for_hiring_manager? && record.position.hiring_manager_ids.include?(member.id)
  end
end
