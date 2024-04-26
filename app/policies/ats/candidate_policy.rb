# frozen_string_literal: true

class ATS::CandidatePolicy < ApplicationPolicy
  alias_rule :show_header?, :show_info?, :show_scorecards?, :show_card?, :show_files?, to: :show?

  def show?
    available_for_active_member?
  end

  def index?
    available_for_employee? || available_for_hiring_manager?
  end
end
