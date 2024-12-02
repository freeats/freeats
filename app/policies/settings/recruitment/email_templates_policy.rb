# frozen_string_literal: true

class Settings::Recruitment::EmailTemplatesPolicy < ApplicationPolicy
  alias_rule :index?, :show?, :new?, :create?, to: :available_for_admin?
end
