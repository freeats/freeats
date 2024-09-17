# frozen_string_literal: true

class NotePolicy < ApplicationPolicy
  alias_rule :show_edit_view?, to: :update?

  def update?
    member.id == record.member_id
  end

  def destroy?
    update? || available_for_admin?
  end
end
