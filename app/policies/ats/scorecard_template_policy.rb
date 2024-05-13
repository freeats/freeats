# frozen_string_literal: true

class ATS::ScorecardTemplatePolicy < ApplicationPolicy
  def show?
    available_for_employee? || visible_for_hiring_manager?
  end

  private

  def visible_for_hiring_manager?
    available_for_hiring_manager? &&
      record.position_stage.position.hiring_manager_ids.include?(member.id)
  end
end
