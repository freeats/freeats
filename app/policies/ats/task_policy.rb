# frozen_string_literal: true

class ATS::TaskPolicy < ApplicationPolicy
  def index?
    available_for_active_member?
  end
end
