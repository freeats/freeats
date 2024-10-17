# frozen_string_literal: true

require "test_helper"

class Tasks::AddTest < ActiveSupport::TestCase
  test "should add task and create events" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    actor_account = accounts(:employee_account)
    name = "Test task"
    due_date = 1.day.from_now.to_date
    description = "Test task description"
    repeat_interval = "monthly"
    taskable_id = candidates(:john).id
    taskable_type = "Candidate"
    assignee_id = members(:admin_member).id
    watcher_ids = [members(:employee_member).id, assignee_id]

    task = nil

    assert_difference ["Task.count", "Event.where(type: 'task_added').count"] do
      assert_difference "Event.where(type: 'task_watcher_added').count", 2 do
        task =
          Tasks::Add.new(
            params: {
              name:,
              due_date:,
              description:,
              repeat_interval:,
              taskable_id:,
              taskable_type:,
              assignee_id:,
              watcher_ids:
            },
            actor_account:
          ).call.value!
      end
    end

    assert_equal task.name, name
    assert_equal task.due_date, due_date
    assert_equal task.description, description
    assert_equal task.repeat_interval, repeat_interval
    assert_equal task.taskable_id, taskable_id
    assert_equal task.taskable_type, taskable_type
    assert_equal task.assignee_id, assignee_id
    assert_equal task.watcher_ids.sort, watcher_ids.sort

    task_added_event = Event.where(type: "task_added").last

    assert_equal task_added_event.eventable, task
    assert_equal task_added_event.actor_account, actor_account

    task_watcher_added_events = Event.where(type: "task_watcher_added").last(2)

    assert_equal task_watcher_added_events.first.eventable, task
    assert_equal task_watcher_added_events.second.eventable, task
    assert_equal task_watcher_added_events.first.changed_field, "watcher"
    assert_equal task_watcher_added_events.second.changed_field, "watcher"
    # watchers are recalculated in operation, so it's hard to keep their order.
    assert_includes watcher_ids, task_watcher_added_events.first.changed_to
    assert_includes watcher_ids, task_watcher_added_events.second.changed_to
  end

  test "should allow to create task without an assignee and watchers" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    actor_account = accounts(:employee_account)
    name = "Test task"
    due_date = 1.week.from_now.to_date
    description = "Test task without assignee and watchers"
    repeat_interval = "never"
    assignee_id = ""

    task = nil

    assert_difference ["Task.count", "Event.where(type: 'task_added').count"] do
      assert_no_difference "Event.where(type: 'task_watcher_added').count" do
        task =
          Tasks::Add.new(
            params: {
              name:,
              due_date:,
              description:,
              repeat_interval:,
              assignee_id:
            },
            actor_account:
          ).call.value!
      end
    end

    assert_equal task.name, name
    assert_equal task.due_date, due_date
    assert_equal task.description, description
    assert_equal task.repeat_interval, repeat_interval
    assert_not task.assignee_id
    assert_empty task.watcher_ids
  end
end
