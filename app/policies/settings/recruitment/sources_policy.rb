# frozen_string_literal: true

class Settings::Recruitment::SourcesPolicy < ApplicationPolicy
  def show?
    available_for_admin?
  end
end
