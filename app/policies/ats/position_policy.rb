# frozen_string_literal: true

class ATS::PositionPolicy < ApplicationPolicy
  alias_rule :show_header?, :show_card?, to: :show?

  def show?
    available_for_employee? ||
      (available_for_hiring_manager? && record.hiring_manager_ids.include?(member.id))
  end

  def index?
    available_for_employee? || available_for_hiring_manager?
  end
end
