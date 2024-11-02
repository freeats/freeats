# frozen_string_literal: true

module ATS::TasksHelper
  def ats_task_due_date(task)
    due_date =
      case task.due_date
      when Time.zone.yesterday then t("core.yesterday")
      when Time.zone.today then t("core.today")
      when Time.zone.tomorrow then t("core.tomorrow")
      else
        if task.due_date.before?(6.days.after) && task.due_date.future?
          task.due_date.strftime("%A")
        elsif task.due_date.year == Time.zone.now.year
          task.due_date.strftime("%b %d")
        else
          task.due_date.strftime("%b %d %Y")
        end
      end

    repeat_icon =
      if task.repeating?
        render(IconComponent.new(
                 :repeat,
                 data: { bs_toggle: :tooltip,
                         bs_title: I18n.t("tasks.repeat_interval.#{task.repeat_interval}") }
               ))
      end

    due_date_slot = tag.span(class: ("text-danger" if task.overdue?)) do
      due_date
    end

    tag.div(class: "hstack gap-2") do
      safe_join [repeat_icon, due_date_slot]
    end
  end

  def ats_task_add_button(taskable: nil)
    url_opts =
      if taskable.nil?
        {}
      else
        { params: { taskable_id: taskable.id, taskable_type: taskable.class.name } }
      end
    form_with(
      url: new_modal_ats_tasks_path(**url_opts),
      data: { action: "turbo:submit-end->tasks#changePath", turbo_frame: :turbo_modal_window }
    ) do
      render ButtonComponent.new.with_content(t("tasks.add_task_button"))
    end
  end

  def ats_task_display_activity(event, oneline: true)
    actor_account_name = compose_actor_account_name(event)

    text = "#{actor_account_name} "

    text <<
      case event.type
      when "note_added"
        "added a note <blockquote class='activity-quote #{
          'text-truncate' if oneline}'>#{
          event.eventable&.text&.truncate(180)}</blockquote>"
      when "note_removed"
        "removed a note"
      when "task_added"
        "created task"
      when "task_changed"
        ats_task_changed_display_activity(event, task_card: true)
      when "task_status_changed"
        "#{event.changed_to == 'open' ? 'reopened' : 'closed'} task"
      when "task_watcher_added"
        "added #{
          event_actor_account_name_for_assignment(event:, member: event.added_watcher)
        } as watcher"
      when "task_watcher_removed"
        "removed #{
          event_actor_account_name_for_assignment(event:, member: event.removed_watcher)
        } as watcher"
      end

    sanitize(text, attributes: %w[data-turbo-frame href])
  end

  def ats_task_changed_display_activity(event, task_card: false)
    field = event.changed_field
    from = event.changed_from
    to = event.changed_to

    case field
    when "due_date"
      from = from&.to_date&.to_fs(:date)
      to = to&.to_date&.to_fs(:date)
    when "repeat_interval"
      from = from.humanize
      to = to.humanize
    when "assignee_id"
      if (from_member = Member.find_by(id: from)).present?
        from = from_member.name
      end
      if (to_member = Member.find_by(id: to)).present?
        to = to_member.name
      end
    end

    if task_card
      if field == "assignee_id" && to.present? && from.present? || field != "assignee_id"
        "changed #{field.humanize} from <b>#{from}</b> to <b>#{to}</b>"
      elsif field == "assignee_id" && to.present?
        "assigned #{event_actor_account_name_for_assignment(event:, member: to_member)} to the task"
      elsif field == "assignee_id" && from.present?
        "unassigned #{event_actor_account_name_for_assignment(event:, member: from_member)} " \
          "from the task"
      end
    elsif field == "assignee_id" && to.present? && from.present? || field != "assignee_id"
      "changed <b>#{event.eventable.name}</b> task's #{field.humanize} " \
        "from <b>#{from}</b> to <b>#{to}</b>"
    elsif field == "assignee_id" && to.present?
      "assigned #{event_actor_account_name_for_assignment(event:, member: to_member)} " \
        "to <b>#{event.eventable.name}</b> task "
    elsif field == "assignee_id" && from.present?
      "unassigned #{event_actor_account_name_for_assignment(event:, member: from_member)} " \
        "from <b>#{event.eventable.name}</b> task "
    end
  end

  def ats_task_assignee_options(assignee_options:, selected_assignee_id:)
    assignee_options.map do |assignee_name, assignee_id|
      { text: assignee_name, value: assignee_id, selected: assignee_id == selected_assignee_id }
    end
  end

  def ats_task_watchers_options(assignee_options:, selected:, disabled:)
    assignee_options.map do |watcher_name, watcher_id|
      {
        text: watcher_name,
        value: watcher_id,
        selected: selected.include?(watcher_id),
        disabled: disabled.include?(watcher_id)
      }
    end
  end

  def ats_task_repeat_interval_options(selected:)
    Task.repeat_intervals.map { |k, v| { text: k.humanize, value: v, selected: v == selected } }
  end
end
