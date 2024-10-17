# frozen_string_literal: true

class ATS::ProfileTasksGrid
  include Datagrid

  #
  # Scope
  #

  scope do
    Task.grid_scope
  end

  #
  # Columns
  #

  column(:status, header: "", html: true, order: false) do |model|
    render partial: "ats/tasks/change_status_control", locals: { task: model, grid: :profiles }
  end

  column(:name, html: true) do |model|
    data = { action: "turbo:submit-end->tasks#changePath", turbo_frame: :turbo_modal_window }
    button_to(
      model.name,
      show_modal_ats_task_path(model, grid: :profiles),
      class: "btn btn-link p-0 text-decoration-none",
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
    order: ->(scope) { scope.joins(assignee: :account).group("account.id").order("accounts.name") }
  ) do |model|
    model.assignee&.account&.name
  end
end
