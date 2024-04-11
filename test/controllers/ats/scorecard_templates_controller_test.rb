# frozen_string_literal: true

require "test_helper"

class ATS::ScorecardTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in accounts(:employee_account)
  end

  test "should get show" do
    scorecard_template = scorecard_templates(:ruby_position_contacted_scorecard_template)

    get ats_scorecard_template_url(scorecard_template)

    assert_response :success
  end

  test "should update scorecard_template to became visible to interviewer and add event" do
    scorecard_template = scorecard_templates(:ruby_position_sourced_scorecard_template)

    assert_not scorecard_template.visible_to_interviewer

    assert_difference "Event.count" do
      patch ats_scorecard_template_url(scorecard_template),
            params: { scorecard_template: { visible_to_interviewer: true } }
    end

    new_event = Event.last

    assert_equal new_event.actor_account_id, accounts(:employee_account).id
    assert_equal new_event.type, "scorecard_template_updated"
    assert_equal new_event.eventable_id, scorecard_template.id

    assert_response :redirect
    assert scorecard_template.reload.visible_to_interviewer
  end

  test "should not create event if scorecard_template was not changed" do
    scorecard_template = scorecard_templates(:ruby_position_sourced_scorecard_template)

    assert_empty scorecard_template.scorecard_template_questions

    params = { scorecard_template: {
      visible_to_interviewer: scorecard_template.visible_to_interviewer,
      title: scorecard_template.title,
      scorecard_template_questions_attributes: {}
    } }

    assert_no_difference "Event.count" do
      patch ats_scorecard_template_url(scorecard_template), params:
    end
  end

  test "should update scorecard_template title" do
    scorecard_template = scorecard_templates(:ruby_position_sourced_scorecard_template)
    new_title = "new title"

    assert_not_equal new_title, scorecard_template.title

    patch ats_scorecard_template_url(scorecard_template),
          params: { scorecard_template: { title: new_title } }

    assert_response :redirect
    assert_equal new_title, scorecard_template.reload.title
  end

  test "should remove question from scorecard_template" do
    scorecard_template = scorecard_templates(:ruby_position_contacted_scorecard_template)

    assert_equal scorecard_template.scorecard_template_questions.count, 1

    # The scorecard_template is always edited with questions, which means that we should destroy
    # the old question in any case, even if the new questions are empty
    patch ats_scorecard_template_url(scorecard_template),
          params: { scorecard_template: { title: scorecard_template.title } }

    assert_response :redirect
    assert_equal scorecard_template.scorecard_template_questions.count, 0
  end

  test "should add question to scorecard_template and new question should have the least list_index" do
    scorecard_template = scorecard_templates(:ruby_position_contacted_scorecard_template)

    questions = scorecard_template.scorecard_template_questions

    assert_equal questions.count, 1
    assert_equal questions.first.list_index, 1

    # The value of the index of the questions in the params does not matter.
    patch ats_scorecard_template_url(scorecard_template),
          params: {
            scorecard_template: {
              scorecard_template_questions_attributes: {
                "11": { question: "new question" },
                "12": { question: questions.first.question }
              }
            }
          }

    assert_response :redirect
    assert_equal questions.count, 2
    assert_equal questions.pluck(:list_index, :question),
                 [[1, "new question"], [2, questions.first.question]]
  end

  test "should create new scorecard_template and add event" do
    position_stage = position_stages(:golang_position_sourced)

    assert_not position_stage.scorecard_template

    assert_difference "ScorecardTemplate.count" => 1, "Event.count" => 1 do
      post ats_scorecard_templates_url, params: { position_stage_id: position_stage.id }
    end

    assert_response :redirect
    assert position_stage.reload.scorecard_template
    assert_equal position_stage.scorecard_template.title, "Sourced stage scorecard template"

    new_event = Event.last

    assert_equal new_event.actor_account_id, accounts(:employee_account).id
    assert_equal new_event.type, "scorecard_template_added"
    assert_equal new_event.eventable_id, position_stage.scorecard_template.id
  end
end
