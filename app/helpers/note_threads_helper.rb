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

  def thread_collapse_button(thread_id, other_thread_notes_size:, expanded:)
    button_tag(
      class: %w[btn btn-link thread-collapse-button text-nowrap
                toggle-chevron-content p-0 mt-2 align-self-start],
      style: ("position: absolute; bottom: 3px;" if expanded),
      data: {
        bs_toggle: :collapse,
        bs_target: "#other-thread-notes-thread-#{thread_id}",
        note_thread_target: "collapseButton"
      },
      type: :button,
      aria: {
        expanded: expanded.to_s,
        controls: "other-thread-notes-thread-#{thread_id}"
      }
    ) do
      safe_join [
        tag.span do
          [
            PrettyNumberComponent.new(other_thread_notes_size).call,
            "reply".pluralize(other_thread_notes_size)
          ].join(" ")
        end,

        tag.span(
          class: "icon-chevron-show ms-1 #{'hidden' if expanded}",
          data: { note_thread_target: "collapsedStateIcon" }
        ) do
          render(IconComponent.new(:chevron_down))
        end,

        tag.span(
          class: "icon-chevron-hide ms-1 #{'hidden' unless expanded}",
          data: { note_thread_target: "collapsedStateIcon" }
        ) do
          render(IconComponent.new(:chevron_up))
        end
      ]
    end
  end
end
