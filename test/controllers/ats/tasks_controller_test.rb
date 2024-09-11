# frozen_string_literal: true

require "test_helper"

class ATS::TasksControllerTest < ActionDispatch::IntegrationTest
  test "should render new modal for each taskable type" do
    sign_in accounts(:employee_account)

    candidate = candidates(:john)
    get new_modal_ats_tasks_url(params: { taskable_id: candidate.id, taskable_type: "Candidate" })

    assert_response :success

    position = positions(:ruby_position)
    get new_modal_ats_tasks_url(params: { taskable_id: position.id, taskable_type: "Position" })

    assert_response :success
  end

  test "should create task and event for candidate" do
    sign_in accounts(:employee_account)

    candidate = candidates(:john)
    assignee = members(:employee_member)

    assert_difference "candidate.tasks.count" do
      assert_difference "Event.where(type: :task_added).count" do
        post ats_tasks_url(
          params: { task: {
            name: "contact",
            assignee_id: assignee.id,
            taskable_id: candidate.id,
            taskable_type: "Candidate",
            due_date: 3.days.from_now,
            watchers: Task.default_watchers(candidate)
          } }
        )
      end
    end
  end
end
