# frozen_string_literal: true

class Settings::Recruitment::EmailTemplatesPolicy < ApplicationPolicy
  alias_rule :index?, :show?, :new?, to: :available_for_admin_on_development?

  def available_for_admin_on_development?
    available_for_admin? && Rails.env.development?
  end
end
