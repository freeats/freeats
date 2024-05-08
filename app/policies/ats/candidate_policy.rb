# frozen_string_literal: true

class ATS::CandidatePolicy < ApplicationPolicy
  alias_rule :show_header?, :show_info?, :show_tasks?, :show_emails?,
             :show_scorecards?, :show_card?, :show_files?, to: :show?

  def show?
    available_for_active_member?
  end

  def index?
    available_for_employee? || available_for_hiring_manager?
  end

  scope_for :hiring_manager do |relation, member_id:|
    next relation if available_for_employee?

    relation
      .select("candidates.*")
      .distinct
      .joins(placements: :position)
      .joins(
        "LEFT JOIN positions_hiring_managers " \
        "ON positions_hiring_managers.position_id = positions.id"
      )
      .joins(
        "LEFT JOIN positions_interviewers ON positions_interviewers.position_id = positions.id"
      )
      .where("positions_hiring_managers.hiring_manager_id = ? " \
             "OR positions_interviewers.interviewer_id = ?", member_id, member_id)
  end
end
