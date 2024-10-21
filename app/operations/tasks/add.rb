# frozen_string_literal: true

class Tasks::Add < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :params, Types::Strict::Hash.schema(
    name: Types::Strict::String,
    due_date: Types::Strict::String | Types::Instance(Date),
    description?: Types::Strict::String,
    repeat_interval?: Types::String.enum(*Task.repeat_intervals.keys),
    taskable_id?: Types::Strict::String.optional | Types::Strict::Integer.optional,
    taskable_type?: Types::Strict::String.optional,
    assignee_id: Types::Strict::String.optional | Types::Strict::Integer.optional,
    watcher_ids?: Types::Strict::Array.of(Types::Strict::String.optional) |
                  Types::Strict::Array.of(Types::Strict::Integer.optional)
  ).strict
  option :actor_account, Types::Instance(Account).optional, optional: true

  def self.result_to_string(result)
    case result
    in Success(_task)
      I18n.t("tasks.successfully_created")
    in Failure(:inactive_assignee)
      I18n.t("tasks.inactive_assignee")
    in Failure(:assignee_not_found)
      I18n.t("tasks.assignee_not_found")
    in Failure[:task_invalid, error]
      error
    end
  end

  def call
    if params[:assignee_id].present?
      assignee = Member.find_by(id: params[:assignee_id])

      return Failure(:assignee_not_found) if assignee.nil?

      return Failure(:inactive_assignee) if assignee.inactive?
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

    return Success() if (task_watchers = task.watchers).empty?

    task_watchers.each do |watcher|
      Events::Add.new(
        params:
          {
            eventable: task,
            changed_field: :watcher,
            type: :task_watcher_added,
            changed_to: watcher.id,
            actor_account:
          }
      ).call
    end

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

    watchers.uniq.compact
  end
end
