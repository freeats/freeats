# frozen_string_literal: true

module ATS::TasksHelper
  def ats_task_due_date(task)
    case task.due_date
    when Time.zone.yesterday then "Yesterday"
    when Time.zone.today then "Today"
    when Time.zone.tomorrow then "Tomorrow"
    else
      if task.due_date.before?(6.days.after) && task.due_date.future?
        task.due_date.strftime("%A")
      elsif task.due_date.year == Time.zone.now.year
        task.due_date.strftime("%b %d")
      else
        task.due_date.strftime("%b %d %Y")
      end
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
      render ButtonComponent.new(size: :small).with_content("Add task")
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
      "changed #{field.humanize} from #{from} to #{to}"
    else
      "changed <b>#{event.eventable.name}</b> task's #{field.humanize} " \
        "from #{from} to #{to}"
    end
  end
end
