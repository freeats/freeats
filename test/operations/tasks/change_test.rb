# frozen_string_literal: true

require "test_helper"

class Tasks::ChangeTest < ActiveSupport::TestCase
  test "should add and remove task watchers" do
    actor_account = accounts(:employee_account)
    task = tasks(:no_taskable)
    old_watcher = members(:employee_member)
    new_watchers = [members(:helen_member), members(:george_member)]
    assignee = members(:admin_member)

    assert_difference ["task.watchers.count", "Event.where(type: :task_changed).count"] do
      Tasks::Change.new(task:, params: { watcher_ids: new_watchers.map { _1.id.to_s } },
                        actor_account:).call.value!
    end

    task.reload

    assert_not_includes task.watchers, old_watcher
    assert_equal task.watchers.sort, (new_watchers + [assignee]).sort
    assert_equal task.assignee, assignee

    Event.last.tap do |task_watchers_changed_event|
      assert_equal task_watchers_changed_event.type, "task_changed"
      assert_equal task_watchers_changed_event.actor_account_id, actor_account.id
      assert_equal task_watchers_changed_event.changed_field, "watcher_ids"
      assert_equal task_watchers_changed_event.changed_from.sort, [old_watcher.id, assignee.id].sort
      assert_equal task_watchers_changed_event.changed_to.sort,
                   [*new_watchers.map(&:id), assignee.id].sort
    end

    new_assignee = new_watchers.first

    assert_no_difference ["Event.where(type: :task_changed, changed_field: 'watcher_ids').count",
                          "task.watchers.count"] do
      assert_difference "Event.where(type: :task_changed).count" do
        Tasks::Change.new(task:, params: { assignee_id: new_assignee.id.to_s }, actor_account:).call.value!
      end
    end

    task.reload

    assert_not_includes task.watchers, old_watcher
    assert_equal task.watchers.sort, [assignee, new_assignee, new_watchers.second].sort
    assert_equal task.assignee, new_assignee

    Event.last.tap do |task_changed_event|
      assert_equal task_changed_event.type, "task_changed"
      assert_equal task_changed_event.actor_account, actor_account
      assert_equal task_changed_event.changed_field, "assignee_id"
      assert_equal task_changed_event.changed_from, assignee.id
      assert_equal task_changed_event.changed_to, new_assignee.id
    end
  end
end
