# frozen_string_literal: true

require "test_helper"

class Tasks::ChangeStatusTest < ActiveSupport::TestCase
  test "closing repeated task should reopen it and change due date" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    task = tasks(:position)

    assert_equal task.due_date, Time.zone.today
    assert_equal task.repeat_interval, "daily"
    assert_equal task.status, "open"

    Tasks::ChangeStatus.new(task:, new_status: "closed", actor_account: accounts(:employee_account)).call.value!

    task.reload

    assert_equal task.due_date, Time.zone.today.next_weekday
    assert_equal task.repeat_interval, "daily"
    assert_equal task.status, "open"
  end
end
