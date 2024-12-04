# frozen_string_literal: true

class Settings::Recruitment::SourcesPolicy < ApplicationPolicy
  alias_rule :index?, :update_all?, to: :available_for_admin?
end
