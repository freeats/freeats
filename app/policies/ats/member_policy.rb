# frozen_string_literal: true

class ATS::MemberPolicy < ApplicationPolicy
  alias_rule :invite?, :deactivate?, :invite?, :reactivate?, to: :available_for_admin?
end
