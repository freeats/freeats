# frozen_string_literal: true

class Settings::Company::GeneralProfilePolicy < ApplicationPolicy
  alias_rule :show?, :update?, to: :available_for_admin?
end
