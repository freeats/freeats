# frozen_string_literal: true

class Settings::Recruitment::EmailTemplatesPolicy < ApplicationPolicy
  alias_rule :index?, :show?, :new?, to: :available_for_admin?
end
