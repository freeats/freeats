# frozen_string_literal: true

class ATS::TasksGrid
  include Datagrid

  #
  # Scope
  #

  scope do
    Task.grid_scope
  end

  attr_accessor :current_member_id

  #
  # Filters
  #

  filter(
    :name,
    :string,
    header: I18n.t("core.name"),
    placeholder: I18n.t("core.name")
  ) do |name|
    where("name ILIKE ?", "%#{name}%")
  end

  filter(
    :status,
    :enum,
    select: -> { Task.statuses.transform_keys(&:capitalize) },
    default: "open",
    include_blank: I18n.t("core.status"),
    placeholder: I18n.t("core.status")
  )

  filter(
    :due_date,
    :enum,
    select: [[I18n.t("core.today"), "today"]],
    default: "today",
    include_blank: I18n.t("core.due_date"),
    placeholder: I18n.t("core.due_date")
  ) do |due_date|
    # Remove this after adding a new option for the due_date filter.
    raise ArgumentError, "Wrong due date" unless due_date == "today"

    past_or_present
  end

  filter(
    :assignee,
    :enum,
    select: lambda {
      Member
        .active
        .or(
          Member
            .where(
              <<~SQL
                EXISTS(
                  SELECT 1
                  FROM tasks
                  WHERE tasks.assignee_id = members.id
                  AND tasks.status = 'open'
                )
              SQL
            )
        )
        .order("accounts.name")
        .pluck("accounts.name", :id)
        .unshift([I18n.t("core.no_assignee"), "nil"])
    },
    include_blank: I18n.t("core.assignee"),
    placeholder: I18n.t("core.assignee")
  ) do |assignee_id|
    where(assignee_id: assignee_id == "nil" ? nil : assignee_id)
  end

  filter(
    :watched,
    :enum,
    select: -> { { I18n.t("core.watched") => "true" } },
    default: "false",
    checkboxes: true
  ) do |val, scope, grid|
    if val.first == "true"
      scope.left_outer_joins(:watchers)
           .where("tasks_watchers.watcher_id = :member_id OR assignee_id = :member_id",
                  member_id: grid.current_member_id)
    end
  end

  #
  # Columns
  #

  column(:task_status, header: "", html: true, order: false) do |model|
    render partial: "ats/tasks/change_status_control", locals: { task: model, grid: :main }
  end

  column(:linked_to, html: true, preload: :taskable) do |model|
    next if model.taskable.nil?

    opts = { data: { turbo_frame: "_top" } }
    case model.taskable
    when Candidate
      link_to(model.taskable_name, tab_ats_candidate_path(model.taskable, :info), **opts)
    when Position
      link_to(model.taskable_name, tab_ats_position_path(model.taskable, :info), **opts)
    else
      raise NotImplementedError, "Unsupported class"
    end
  end

  column(:name, html: true) do |model|
    data = { action: "turbo:submit-end->tasks#changePath", turbo_frame: :turbo_modal_window }
    button_to(
      model.name,
      show_modal_ats_task_path(model),
      class: "btn btn-link p-0 text-start",
      form: { data: }
    )
  end

  column(
    :notes,
    header: I18n.t("core.notes"),
    &:notes_count
  )

  column(
    :due_date,
    header: I18n.t("core.due"),
    html: true,
    order: "due_date, name",
    order_desc: "due_date DESC, name"
  ) do |model|
    ats_task_due_date(model)
  end

  column(
    :assignee,
    html: true,
    preload: { assignee: :account },
    order: ->(scope) {
             scope.left_outer_joins(assignee: :account).group("accounts.id").order("accounts.name")
           }
  ) do |model|
    model.assignee&.account&.name
  end
end
