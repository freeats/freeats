# frozen_string_literal: true

class Settings::Recruitment::EmailTemplatesPolicy < ApplicationPolicy
  alias_rule :index?, :show?, :new?, to: :available_for_admin_on_local?

  def available_for_admin_on_local?
    available_for_admin? && Rails.env.local?
  end
end
