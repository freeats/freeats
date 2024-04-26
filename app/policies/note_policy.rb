# frozen_string_literal: true

class NotePolicy < ApplicationPolicy
  alias_rule :show_edit_view?, to: :update?
  alias_rule :create?, :reply?, :show_show_view?,
             :add_reaction?, :remove_reaction?, to: :available_for_active_member?

  def update?
    member.id == record.member_id
  end

  def destroy?
    update? || available_for_admin?
  end
end
