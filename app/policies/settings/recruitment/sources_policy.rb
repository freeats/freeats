# frozen_string_literal: true

class Settings::Recruitment::SourcesPolicy < ApplicationPolicy
  # TODO: Functionality in the process of implementation.
  def show?
    Rails.env.development? && available_for_admin?
  end
end
