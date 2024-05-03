# frozen_string_literal: true

class ATS::ScorecardTemplatePolicy < ApplicationPolicy
  def show?
    available_for_employee? || available_for_hiring_manager?
  end
end
