# frozen_string_literal: true

class ATS::TasksController < AuthorizedController
  include Dry::Monads[:result]

  layout "ats/application"

  before_action { @nav_item = :tasks }
  before_action :set_task, only: %i[show show_modal update update_status]
  before_action :set_taskable, only: %i[new new_modal]
  before_action :set_time_before_update, only: %i[update update_status]
  before_action :authorize!

  def index
    session[:ats_tasks_grid_params] = task_grid_params
    set_tasks_grid
  end

  def show
    case @task.taskable
    when Candidate then redirect_to task_ats_candidate_path(@task.taskable, @task)
    when Position then redirect_to task_ats_position_path(@task.taskable, @task)
    else
      set_tasks_grid
      @lazy_load_form_url = show_modal_ats_task_path(@task)
      render :index
    end
  end

  def new
    set_tasks_grid
    @lazy_load_form_url = new_modal_ats_tasks_path
    render :index
  end

  def new_modal
    taskable_name = @taskable.try(:name) || @taskable.try(:full_name) if @taskable
    modal_options = {
      partial: "new",
      layout: "modal",
      locals: {
        modal_id: "new",
        form_options: { url: ats_tasks_path, data: { turbo_frame: :turbo_tasks_grid } },
        modal_size: "modal-lg",
        assignee_options:,
        default_assignee:,
        default_watchers: Task.default_watchers(@taskable).map(&:id),
        current_member:,
        taskable: @taskable,
        taskable_name:,
        hidden_fields: { path_ending: "new" }
      }
    }
    if @taskable
      modal_options[:locals][:hidden_fields].merge!(
        { "task[taskable_id]": @taskable.id, "task[taskable_type]": @taskable.class.name }
      )
    end
    render(modal_options)
  end

  def show_modal
    note_threads =
      NoteThread
      .includes(notes: %i[added_event member reacted_members])
      .preload(:members)
      .where(notable: @task)
      .order("note_threads.id DESC", "notes.id")
      .visible_to(current_member)
    render(
      partial: "show",
      locals: {
        task: @task,
        assignee_options:,
        added_by_account: @task.added_event.actor_account,
        added_on_time: @task.added_event.performed_at,
        all_active_members:,
        suggested_names: all_active_members.map(&:name),
        note_threads:,
        all_activities: @task.activities,
        grid: params[:grid],
        hidden_fields: { path_ending: @task.id.to_s }
      }
    )
  end

  def create
    result = Tasks::Add.new(
      params: task_params.to_h.deep_symbolize_keys,
      actor_account: current_account
    ).call
    case result
    in Success(task)
      render_tasks_grid(task)
    in Failure(:inactive_assignee) | Failure(:assignee_not_found) | Failure[:task_invalid, _error]
      error_message = Tasks::Add.result_to_string(result)
      render_error(error_message)
    end
  end

  def update
    case Tasks::Change.new(
      task: @task,
      params: task_params.to_h.deep_symbolize_keys,
      actor_account: current_account
    ).call
    in Success(_task)
      render_task_card
    in Failure[:task_invalid, _error]
      render_error _error, status: :unprocessable_entity
    end
  end

  def update_status
    case Tasks::ChangeStatus.new(
      task: @task,
      new_status: params.dig(:task, :status),
      actor_account: current_account
    ).call
    in Success[_task]
      render_task_card
    in Failure[:task_invalid, _error]
      render_error _error, status: :unprocessable_entity
    end
  end

  private

  def assignee_options
    return @assignee_options if @assignee_options.present?

    @assignee_options =
      Member
      .joins(:account)
      .active
      .order("accounts.name ASC")
      .pluck("accounts.name", :id)

    if @task&.assignee.present?
      @assignee_options << [@task.assignee.account.name, @task.assignee.id]
    end
    @assignee_options = @assignee_options.uniq
  end

  def default_assignee
    if (@taskable.is_a?(Candidate) || @taskable.is_a?(Position)) && @taskable.recruiter&.active?
      return @taskable.recruiter_id
    end

    current_member.id
  end

  def all_active_members
    Member.active.where.not(id: current_member.id).includes(:account)
  end

  def extract_task_variables(task)
    case task.taskable
    when Candidate
      @candidate = task.taskable
      @tasks_grid = ATS::ProfileTasksGrid.new(helpers.add_default_sorting({}, :due_date, :desc))
      @tasks_grid.scope { _1.where(taskable: @candidate).page(params[:page]).per(10) }
    when Position
      @position = task.taskable
      @tasks_grid = ATS::ProfileTasksGrid.new(helpers.add_default_sorting({}, :due_date, :desc))
      @tasks_grid.scope { _1.where(taskable: @position).page(params[:page]).per(10) }
    else
      set_tasks_grid(grid_params: session[:ats_tasks_grid_params])
    end
  end

  def set_tasks_grid(grid_params: nil)
    grid_params ||=
      task_grid_params || {}
    grid_params = grid_params.symbolize_keys
    grid_params[:current_member_id] = current_member.id
    grid_params[:assignee] ||= current_member.id
    @tasks_grid = ATS::TasksGrid.new(
      helpers.add_default_sorting(
        grid_params,
        :due_date
      )
    ) do |scope|
      scope.page(params[:page])
    end
  end

  def render_tasks_grid(task)
    extract_task_variables(task)

    render_turbo_stream(
      [
        turbo_stream.replace(:turbo_tasks_grid, partial: "tasks_grid"),
        turbo_stream.replace(
          :turbo_navbar_tasks_counter,
          partial: "ats/tasks/navbar_counter",
          locals: { pending_tasks_count: current_member.tasks_count }
        ),
        if task.taskable
          turbo_stream.replace_all(
            ".turbo_tab_tasks_counter",
            partial: "ats/tasks/tab_counter",
            locals: { pending_tasks_count: Task.where(taskable: task.taskable).open.size }
          )
        end
      ],
      notice: t("tasks.successfully_created")
    )
  end

  def render_task_card
    new_activities =
      if (new_events = @task.activities(since: @time_before_update))
        new_events.to_a.sort_by(&:performed_at).map do |event|
          turbo_stream.prepend(
            :turbo_task_event_list,
            partial: "ats/tasks/activity_event_row",
            locals: { event: }
          )
        end
      else
        []
      end

    # Setting taskable to nil will cause the following method to call set_tasks_grid method.
    @task.taskable = nil unless params[:grid] == "profiles"
    task_dom_id = ActionView::RecordIdentifier.dom_id(@task)
    extract_task_variables(@task)
    render_turbo_stream(
      [
        turbo_stream.replace(
          :turbo_task_main_content,
          partial: "ats/tasks/main_content",
          locals: {
            task: @task,
            assignee_options:,
            added_by_account: @task.added_event.actor_account,
            added_on_time: @task.added_event.performed_at,
            grid: params[:grid]
          }
        ),
        turbo_stream.replace(
          :turbo_navbar_tasks_counter,
          partial: "ats/tasks/navbar_counter",
          locals: { pending_tasks_count: current_member.tasks_count }
        ),
        turbo_stream.replace(
          task_dom_id,
          helpers.ats_datagrid_render_row(@tasks_grid, Task.grid_scope.find(params[:id]))
        ),
        if @task.taskable
          turbo_stream.replace_all(
            ".turbo_tab_tasks_counter",
            partial: "ats/tasks/tab_counter",
            locals: { pending_tasks_count: Task.where(taskable: @task.taskable).open.size }
          )
        end,
        *new_activities
      ]
    )
  end

  def set_task
    @task = Task.find(params[:id])
  end

  def set_taskable
    @taskable =
      [Candidate, Position]
      .find { _1.name == params[:taskable_type] }
      &.find(params[:taskable_id])
  end

  def set_time_before_update
    @time_before_update = Time.zone.now
  end

  def task_params
    params
      .require(:task)
      .permit(
        :name,
        :due_date,
        :description,
        :repeat_interval,
        :taskable_id,
        :taskable_type,
        :assignee_id,
        watcher_ids: []
      )
  end

  def task_grid_params
    params
      .fetch(:ats_tasks_grid, nil)
      &.permit(:assignee, :descending, :due_date, :status, :name, :order, watched: [])
      &.to_h
  end
end
