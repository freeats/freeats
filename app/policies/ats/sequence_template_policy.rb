# frozen_string_literal: true

class ATS::SequenceTemplatePolicy < ApplicationPolicy
  def show?
    available_for_employee? || available_for_hiring_manager?
  end
end
