# frozen_string_literal: true

class ATS::PlacementPolicy < ApplicationPolicy
  def destroy?
    (available_for_admin? || placement_creator?) &&
      record.stage == "Sourced" && record.scorecards.blank?
    # TODO: After implementing sequences.
    # && record.sequences.blank?
  end

  private

  def placement_creator?
    return false unless record.added_event.actor_account

    record.added_event.actor_account.member.id == member.id
  end
end
