# frozen_string_literal: true

class ATS::ScorecardPolicy < ApplicationPolicy
  def destroy?
    available_for_admin? || scorecard_creator?
  end

  private

  def scorecard_creator?
    record.author.id == member.id
  end
end
