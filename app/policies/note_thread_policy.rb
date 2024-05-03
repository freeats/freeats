# frozen_string_literal: true

class NoteThreadPolicy < ApplicationPolicy
  def update?
    available_for_active_member?
  end
end
