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

  scope_for :hiring_manager do |relation, member_id:|
    next relation if available_for_employee?

    relation
      .select("positions.*")
      .joins(
        "JOIN positions_hiring_managers ON positions_hiring_managers.position_id = positions.id"
      )
      .where(positions_hiring_managers: { hiring_manager_id: member_id })
  end
end
