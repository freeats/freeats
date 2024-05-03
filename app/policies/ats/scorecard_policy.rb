# frozen_string_literal: true

class ATS::ScorecardPolicy < ApplicationPolicy
  alias_rule :edit?, :update?, to: :show?
  alias_rule :create?, to: :new?

  def show?
    available_for_employee? || available_for_hiring_manager? ||
      available_for_interviewer? && record.visible_to_interviewer
  end

  def new?
    available_for_employee? || available_for_hiring_manager? || (available_for_interviewer? &&
      record.position_stage&.scorecard_template&.visible_to_interviewer)
  end
end
