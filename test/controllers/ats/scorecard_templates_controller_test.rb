# frozen_string_literal: true

require "test_helper"

class ATS::ScorecardTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in accounts(:employee_account)
  end

  test "should compose the new scorecard_template" do
    position_stage = position_stages(:ruby_position_contacted)

    assert_no_difference "ScorecardTemplate.count" do
      get new_ats_scorecard_template_path(position_stage_id: position_stage.id)
    end

    assert_response :success

    doc = Nokogiri::HTML::Document.parse(response.body)

    assert_equal doc.at_css("#scorecard_template_position_stage_id").attr(:value), position_stage.id.to_s
    assert_equal doc.at_css("#scorecard_template_title").attr(:value), "Contacted stage scorecard template"
  end

  test "should get show" do
    scorecard_template = scorecard_templates(:ruby_position_contacted_scorecard_template)

    get ats_scorecard_template_url(scorecard_template)

    assert_response :success
  end

  test "should not create event if scorecard_template was not changed" do
    scorecard_template = scorecard_templates(:ruby_position_sourced_scorecard_template)

    assert_empty scorecard_template.scorecard_template_questions

    params = { scorecard_template: {
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

  test "should create new scorecard_template with question and add event" do
    position_stage = position_stages(:golang_position_sourced)

    assert_not position_stage.scorecard_template

    params = { scorecard_template: {
      title: "Sourced stage scorecard template",
      position_stage_id: position_stage.id,
      scorecard_template_questions_attributes: { "0": { question: "How was the candidate's communication?" } }
    } }
    assert_difference "ScorecardTemplate.count" => 1, "Event.count" => 1, "ScorecardTemplateQuestion.count" => 1 do
      post ats_scorecard_templates_url, params:
    end

    assert_response :redirect

    scorecard_template = ScorecardTemplate.last
    scorecard_template_question = ScorecardTemplateQuestion.last

    assert_equal scorecard_template.position_stage_id, position_stage.id
    assert_equal scorecard_template.title, params[:scorecard_template][:title]

    assert_equal scorecard_template_question.scorecard_template_id, scorecard_template.id
    assert_equal scorecard_template_question.question,
                 params[:scorecard_template][:scorecard_template_questions_attributes].values.first[:question]

    new_event = Event.last

    assert_equal new_event.actor_account_id, accounts(:employee_account).id
    assert_equal new_event.type, "scorecard_template_added"
    assert_equal new_event.eventable_id, scorecard_template.id
  end

  test "should allow to destroy scorecard templates to admins only" do
    scorecard_template = scorecard_templates(:ruby_position_contacted_scorecard_template)
    position = scorecard_template.position_stage.position
    assert_no_difference "ScorecardTemplate.count" do
      delete ats_scorecard_template_path(scorecard_template)
    end

    assert_response :redirect
    assert_redirected_to "/"
    assert scorecard_template.reload

    sign_out
    sign_in accounts(:admin_account)

    assert_difference "ScorecardTemplate.count", -1 do
      delete ats_scorecard_template_path(scorecard_template)
    end

    assert_response :redirect
    assert_redirected_to ats_position_path(position)
    assert_nil ScorecardTemplate.find_by(id: scorecard_template.id)
  end

  test "should render error if scorecard template was not destroyed" do
    sign_out
    sign_in accounts(:admin_account)
    scorecard_template = scorecard_templates(:ruby_position_contacted_scorecard_template)

    scorecard_template_destroy_mock = Minitest::Mock.new
    scorecard_template_destroy_mock.expect(:call, Failure[:scorecard_template_not_destroyed, "error message"])

    ScorecardTemplates::Destroy.stub(:new, ->(_params) { scorecard_template_destroy_mock }) do
      err = assert_raises(RenderErrorExceptionForTests) do
        delete(ats_scorecard_template_path(scorecard_template))
      end

      err_info = JSON.parse(err.message)

      assert_equal err_info["message"], "error message"
      assert_equal err_info["status"], "unprocessable_entity"
    end
  end
end
