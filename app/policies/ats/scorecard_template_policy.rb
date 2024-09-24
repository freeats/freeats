# frozen_string_literal: true

class ATS::ScorecardTemplatePolicy < ApplicationPolicy
  alias_rule :destroy?, to: :available_for_admin?
end
