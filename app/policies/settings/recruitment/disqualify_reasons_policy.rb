# frozen_string_literal: true

class Settings::Recruitment::DisqualifyReasonsPolicy < ApplicationPolicy
  def index?
    available_for_admin?
  end

  def bulk_update?
    index?
  end
end
