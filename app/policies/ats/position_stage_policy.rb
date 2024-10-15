# frozen_string_literal: true

class ATS::PositionStagePolicy < ApplicationPolicy
  alias_rule :destroy?, to: :available_for_admin?
end
