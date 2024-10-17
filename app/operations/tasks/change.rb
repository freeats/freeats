# frozen_string_literal: true

class Tasks::Change < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :task, Types::Instance(Task)
  option :params, Types::Strict::Hash.schema(
    name?: Types::Strict::String,
    due_date?: Types::Strict::String | Types::Instance(Date),
    description?: Types::Strict::String,
    repeat_interval?: Types::String.enum(*Task.repeat_intervals.keys),
    assignee_id?: Types::Strict::String.optional,
    watcher_ids?: Types::Strict::Array.of(Types::Strict::String.optional)
  ).strict
  option :actor_account, Types::Instance(Account)

  def call
    old_values = {
      name: task.name,
      due_date: task.due_date,
      repeat_interval: task.repeat_interval,
      assignee_id: task.assignee_id,
      watcher_ids: task.watchers.ids
    }

    params[:watcher_ids] = watchers.map(&:id)

    task.assign_attributes(params)

    ActiveRecord::Base.transaction do
      yield save_task(task)
      yield add_task_changed_events(old_values:, task:, actor_account:)
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

  def add_task_changed_events(old_values:, task:, actor_account:)
    old_values.each do |field, old_value|
      new_value = task.public_send(field)
      if field == :watcher_ids
        (new_value - old_value).each do |new_watcher|
          Events::Add.new(
            params:
              {
                eventable: task,
                changed_field: :watcher,
                type: :task_watcher_added,
                changed_to: new_watcher,
                actor_account:
              }
          ).call
        end
        (old_value - new_value).each do |removed_watcher|
          Events::Add.new(
            params:
              {
                eventable: task,
                changed_field: :watcher,
                type: :task_watcher_removed,
                changed_from: removed_watcher,
                actor_account:
              }
          ).call
        end
      else
        Events::AddChangedEvent.new(
          eventable: task,
          changed_field: field,
          old_value:,
          new_value:,
          actor_account:
        ).call
      end
    end

    Success()
  end

  def watchers
    watchers =
      if params[:watcher_ids].present?
        [task.assignee, *Member.active.where(id: params[:watcher_ids])]
      elsif params[:assignee_id].present? && task.assignee_id != params[:assignee_id]
        [*task.watchers, Member.find_by(id: params[:assignee_id])]
      else
        [*task.watchers]
      end

    watchers.uniq.compact
  end
end
