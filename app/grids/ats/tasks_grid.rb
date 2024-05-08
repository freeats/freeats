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
    header: "Name",
    placeholder: "Name"
  ) do |name|
    where("name ILIKE ?", "%#{name}%")
  end

  filter(
    :status,
    :enum,
    select: -> { Task.statuses.transform_keys(&:capitalize) },
    default: "open",
    include_blank: "Status",
    placeholder: "Status"
  )

  filter(
    :due_date,
    :enum,
    select: [%w[Today today]],
    default: "today",
    include_blank: "Due date",
    placeholder: "Due date"
  ) do |due_date|
    # Remove this after adding a new option for the due_date filter.
    raise "Wrong due date" unless due_date == "today"

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
    },
    include_blank: "Assignee",
    placeholder: "Assignee"
  )

  filter(
    :watched,
    :enum,
    select: -> { { "Watched" => "true" } },
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

  column(:status, header: "", html: true, order: false) do |model|
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
      raise "Unsupported class"
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
    header: "Notes",
    &:notes_count
  )

  column(
    :due_date,
    header: "Due",
    html: true,
    order: "due_date, name",
    order_desc: "due_date DESC, name"
  ) do |model|
    overdue_class = model.overdue? ? "text-danger" : ""
    tag.span(class: overdue_class) do
      ats_task_due_date(model)
    end
  end

  column(
    :assignee,
    html: true,
    preload: { assignee: :account },
    order: ->(scope) { scope.joins(assignee: :account).group("accounts.id").order("accounts.name") }
  ) do |model|
    model.assignee.account.name
  end
end
