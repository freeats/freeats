# frozen_string_literal: true

class ApplicationPolicy < ActionPolicy::Base
  include ActionPolicy::Policy::Core
  include ActionPolicy::Policy::Authorization
  include ActionPolicy::Policy::PreCheck
  include ActionPolicy::Policy::Reasons
  include ActionPolicy::Policy::Aliases
  include ActionPolicy::Policy::Scoping
  include ActionPolicy::Policy::Cache
  include ActionPolicy::Policy::CachedApply
  include ActionPolicy::Policy::Defaults

  authorize :member, allow_nil: true

  # Default_rule makes :available_for_member? match anything that is
  # not :index?, :create? or :new?
  default_rule :available_for_member?

  # Alias_rule added to makes :available_for_member? match anything.
  # More info in https://actionpolicy.evilmartians.io/#/aliases
  alias_rule :index?, :create?, :new?, to: :available_for_member?

  def available_for_member?
    member.member? || member.admin?
  end

  def available_for_admin?
    member.admin?
  end
end
