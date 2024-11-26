# frozen_string_literal: true

class Settings::Company::GeneralPolicy < ApplicationPolicy
  # TODO: Functionality in the process of implementation.
  def show?
    false || (Rails.env.development? && available_for_admin?)
  end
end
