# frozen_string_literal: true

class ATS::CandidatePolicy < ApplicationPolicy
  alias_rule :destroy?, to: :available_for_admin?
end
