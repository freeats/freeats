# frozen_string_literal: true

class Tasks::Add
  include Dry::Monads[:result, :do]

  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash.schema(
      name: Types::Strict::String,
      due_date: Types::Strict::String | Types::Instance(Date),
      description?: Types::Strict::String,
      repeat_interval: Types::String.enum(*Task.repeat_intervals.keys),
      taskable_id?: Types::Strict::String.optional,
      taskable_type?: Types::Strict::String.optional,
      assignee_id: Types::Strict::String.optional,
      watcher_ids?: Types::Strict::Array.of(Types::Strict::String.optional)
    ).strict
    option :actor_account, Types::Instance(Account)
  end

  def call
    if Member.find(params[:assignee_id]).inactive?
      return Failure[:inactive_assignee, "Assignee must be an active member."]
    end

    params[:watcher_ids] = watchers.map(&:id)

    task = Task.new(params)

    ActiveRecord::Base.transaction do
      yield save_task(task)
      yield add_events(task:, actor_account:)
    end

    Success(task)
  end

  private

  def save_task(task)
    task.save!

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:task_invalid, task.errors.full_messages.presence || e.to_s]
  end

  def add_events(task:, actor_account:)
    task_added_params = {
      actor_account:,
      type: :task_added,
      eventable: task
    }

    yield Events::Add.new(params: task_added_params).call

    return Success() if task.watchers.empty?

    Events::AddChangedEvent.new(
      eventable: task,
      changed_field: :watcher_ids,
      old_value: [],
      new_value: task.watchers.ids,
      actor_account:
    ).call

    Success()
  end

  def watchers
    watchers =
      if params[:watcher_ids].present?
        Member.active.where(id: [*params[:watcher_ids], params[:assignee_id]]).to_a
      else
        taskable =
          [Candidate, Position]
          .find { _1.name == params[:taskable_type] }
          &.find(params[:taskable_id])

        [*Task.default_watchers(taskable), Member.find_by(id: params[:assignee_id])]
      end

    watchers.uniq
  end
end