# frozen_string_literal: true

class ATS::QuickSearchPolicy < ApplicationPolicy
  def index?
    available_for_employee? || available_for_hiring_manager?
  end
end
