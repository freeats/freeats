# frozen_string_literal: true

class ATS::CandidatePolicy < ApplicationPolicy
  alias_rule :show_header?, :show_card?,
             :show_info?, :show_tasks?, :show_scorecards?, :show_files?, to: :show?

  def show?
    available_for_employee? || visible_for_hiring_manager? || visible_for_interviewer?
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
        "ON positions_hiring_managers.position_id = positions.id " \
        "LEFT JOIN positions_interviewers ON positions_interviewers.position_id = positions.id"
      )
      .where("positions_hiring_managers.hiring_manager_id = ? " \
             "OR positions_interviewers.interviewer_id = ?", member_id, member_id)
  end

  private

  def visible_for_hiring_manager?
    available_for_hiring_manager? &&
      (assigned_to_position_with_hiring_manager? || assigned_to_position_with_interviewer?)
  end

  def visible_for_interviewer?
    available_for_interviewer? && assigned_to_position_with_interviewer?
  end

  def assigned_to_position_with_hiring_manager?
    Candidate
      .joins(placements: :position)
      .joins(
        "JOIN positions_hiring_managers ON positions_hiring_managers.position_id = positions.id"
      )
      .where(candidates: { id: record.id })
      .exists?(positions_hiring_managers: { hiring_manager_id: member.id })
  end

  def assigned_to_position_with_interviewer?
    Candidate
      .joins(placements: :position)
      .joins(
        "JOIN positions_interviewers ON positions_interviewers.position_id = positions.id"
      )
      .where(candidates: { id: record.id })
      .exists?(positions_interviewers: { interviewer_id: member.id })
  end
end
