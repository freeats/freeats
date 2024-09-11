# frozen_string_literal: true

module NoteThreadsHelper
  def note_thread_compose_user_options_for_select(thread:, all_active_members:)
    unchangeable_ids =
      [current_member, *thread.participants, *thread.mentioned_members].map(&:id)
    selected_ids = [*unchangeable_ids, *thread.members.map(&:id)]

    ids = [
      current_member,
      *thread.participants,
      *thread.mentioned_members,
      *thread.members,
      *all_active_members
    ].map(&:id)

    Member.includes(:account).where(id: ids).map do |member|
      {
        value: member.id,
        text: member.account.name,
        selected: selected_ids.include?(member.id),
        disabled: unchangeable_ids.include?(member.id)
      }
    end
  end
end
