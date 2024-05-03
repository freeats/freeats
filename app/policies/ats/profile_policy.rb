# frozen_string_literal: true

class ATS::ProfilePolicy < ApplicationPolicy
  def show?
    available_for_active_member?
  end
end
