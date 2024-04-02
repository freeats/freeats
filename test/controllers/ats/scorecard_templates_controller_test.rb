# frozen_string_literal: true

require "test_helper"

class ATS::ScorecardTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in accounts(:employee_account)
  end

  test "should get show" do
    scorecard_template = scorecard_templates(:ruby_position_contacted)

    get ats_scorecard_template_url(scorecard_template)

    assert_response :success
  end

  test "should update scorecard_template to became visible to interviewer" do
    scorecard_template = scorecard_templates(:ruby_position_sourced)

    assert_not scorecard_template.visible_to_interviewer

    patch ats_scorecard_template_url(scorecard_template),
          params: { scorecard_template: { visible_to_interviewer: true } }

    assert_response :redirect
    assert scorecard_template.reload.visible_to_interviewer
  end

  test "should update scorecard_template title" do
    scorecard_template = scorecard_templates(:ruby_position_sourced)
    new_title = "new title"

    assert_not_equal new_title, scorecard_template.title

    patch ats_scorecard_template_url(scorecard_template),
          params: { scorecard_template: { title: new_title } }

    assert_response :redirect
    assert_equal new_title, scorecard_template.reload.title
  end

  test "should remove question from scorecard_template" do
    scorecard_template = scorecard_templates(:ruby_position_contacted)

    assert_equal scorecard_template.scorecard_template_questions.count, 1

    # The scorecard_template is always edited with questions, which means that we should destroy
    # the old question in any case, even if the new questions are empty
    patch ats_scorecard_template_url(scorecard_template),
          params: { scorecard_template: { title: scorecard_template.title } }

    assert_response :redirect
    assert_equal scorecard_template.scorecard_template_questions.count, 0
  end

  test "should add question to scorecard_template and new question should have the least list_index" do
    scorecard_template = scorecard_templates(:ruby_position_contacted)

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

  test "should create new scorecard_template" do
    position_stage = position_stages(:golang_position_sourced)

    assert_not position_stage.scorecard_template

    post ats_scorecard_templates_url, params: { position_stage_id: position_stage.id }

    assert_response :redirect
    assert position_stage.reload.scorecard_template
    assert_equal position_stage.scorecard_template.title, "Sourced stage scorecard template"
  end
end
