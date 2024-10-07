# frozen_string_literal: true

class NoteThread < ApplicationRecord
  acts_as_tenant(:tenant)

  has_and_belongs_to_many :members

  has_many :notes, dependent: :destroy

  belongs_to :notable, polymorphic: true

  scope :visible_to, lambda { |member|
    left_outer_joins(:members)
      .where("members.id = ? AND hidden = true OR hidden = false", member.id)
      .distinct
  }

  def update_visibility_settings(params, current_member:)
    self.members =
      if params[:hidden] != "true" && hidden
        [current_member]
      else
        Member.where(id: [*params[:members], *mentioned_members, current_member])
      end
    self.hidden = params[:hidden]

    save!
  end

  def mentioned_members
    mentioned_member_ids = notes.flat_map do |note|
      Note.mentioned_members_ids(note.text)
    end

    Member.where(id: mentioned_member_ids)
  end

  def participants
    notes.map(&:member).uniq
  end
end
