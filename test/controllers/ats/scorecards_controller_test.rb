# frozen_string_literal: true

require "test_helper"

class ATS::ScorecardssControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in accounts(:employee_account)
  end

  test "should compose the new scorecard" do
    position_stage = position_stages(:ruby_position_contacted)
    placement = placements(:sam_ruby_contacted)
    scorecard_template = scorecard_templates(:ruby_position_contacted_scorecard_template)
    scorecard_template_question =
      scorecard_template_questions(:ruby_position_contacted_first_scorecard_template_question)

    assert_no_difference "Scorecard.count" do
      get new_ats_scorecard_path(position_stage_id: position_stage.id, placement_id: placement.id)
    end

    assert_response :success

    doc = Nokogiri::HTML::Document.parse(response.body)

    assert_equal doc.at_css("#scorecard_position_stage_id").attr(:value), position_stage.id.to_s
    assert_equal doc.at_css("#scorecard_placement_id").attr(:value), placement.id.to_s
    assert_equal doc.at_css("#scorecard_title").attr(:value), "#{scorecard_template.title} scorecard"

    assert_includes doc.css(".card-title").text, scorecard_template_question.question
  end

  test "should create the scorecard with question" do
    scorecard_template = scorecard_templates(:ruby_position_contacted_scorecard_template)
    scorecard_template_question =
      scorecard_template_questions(:ruby_position_contacted_first_scorecard_template_question)
    position_stage = position_stages(:ruby_position_contacted)
    placement = placements(:sam_ruby_contacted)
    member = members(:employee_member)

    params = {
      title: "#{scorecard_template.title} scorecard",
      position_stage_id: position_stage.id,
      placement_id: placement.id,
      interviewer_id: member.id,
      score: "good",
      scorecard_questions_attributes:
        { "0" => { question: scorecard_template_question.question, answer: "Yes" } }
    }

    assert_difference "Scorecard.count" do
      post(ats_scorecards_path, params: { scorecard: params })
    end

    assert_response :redirect

    scorecard = Scorecard.last

    assert_equal scorecard.title, params[:title]
    assert_equal scorecard.position_stage_id, position_stage.id
    assert_equal scorecard.placement_id, placement.id
    assert_equal (scorecard.scorecard_questions.pluck(:question) +
                 [scorecard_template_question.question]).uniq,
                 ["What is your favorite color?"]
    assert_equal scorecard.scorecard_questions.map { _1.answer.to_s },
                 ["<div class=\"trix-content\">\n  Yes\n</div>\n"]
  end

  test "should not create the scorecard without required params" do
    scorecard_template = scorecard_templates(:ruby_position_contacted_scorecard_template)
    position_stage = position_stages(:ruby_position_contacted)
    placement = placements(:sam_ruby_contacted)
    member = members(:employee_member)

    # without score
    params = {
      title: "#{scorecard_template.title} scorecard",
      position_stage_id: position_stage.id,
      placement_id: placement.id,
      interviewer_id: member.id
    }

    assert_no_difference "Scorecard.count" do
      error = assert_raises(Dry::Types::MissingKeyError) do
        post(ats_scorecards_path, params: { scorecard: params })
      end

      assert_equal error.message, ":score is missing in Hash input"
    end

    # without interviewer
    params = {
      title: "#{scorecard_template.title} scorecard",
      position_stage_id: position_stage.id,
      placement_id: placement.id,
      score: "good"
    }

    assert_no_difference "Scorecard.count" do
      error = assert_raises(Dry::Types::MissingKeyError) do
        post(ats_scorecards_path, params: { scorecard: params })
      end

      assert_equal error.message, ":interviewer_id is missing in Hash input"
    end
  end

  test "should update the scorecard with question" do
    scorecard = scorecards(:ruby_position_contacted_scorecard)
    scorecard_question = scorecard_questions(:ruby_position_contacted_first_scorecard_question)
    member = members(:employee_member)

    params = {
      interviewer_id: member.id,
      score: "irrelevant",
      scorecard_questions_attributes: {
        "0" => { id: scorecard_question.id, answer: "I do not know where is Gandalf" }
      }
    }

    assert_not_equal scorecard.interviewer_id, params[:interviewer_id]
    assert_not_equal scorecard.score, params[:score]
    assert_not_equal scorecard_question.answer, params[:scorecard_questions_attributes]["0"][:answer]

    assert_no_difference "Scorecard.count" do
      patch ats_scorecard_path(scorecard), params: { scorecard: params, id: scorecard.id }
    end

    scorecard.reload
    scorecard_question.reload

    assert_equal scorecard.interviewer_id, params[:interviewer_id]
    assert_equal scorecard.score, params[:score]
    assert_equal scorecard_question.answer.to_s,
                 "<div class=\"trix-content\">\n  #{params[:scorecard_questions_attributes]['0'][:answer]}\n</div>\n"
  end

  test "should update scorecard without question" do
    scorecard = scorecards(:ruby_position_replied_scorecard)
    member = members(:employee_member)

    assert_empty scorecard.scorecard_questions

    params = {
      interviewer_id: member.id,
      score: "irrelevant"
    }

    assert_not_equal scorecard.interviewer_id, params[:interviewer_id]
    assert_not_equal scorecard.score, params[:score]

    assert_no_difference "Scorecard.count" do
      patch ats_scorecard_path(scorecard), params: { scorecard: params, id: scorecard.id }
    end

    scorecard.reload

    assert_equal scorecard.interviewer_id, params[:interviewer_id]
    assert_equal scorecard.score, params[:score]
    assert_empty scorecard.scorecard_questions
  end

  test "should allow to destroy scorecard to its author, that has no admin access level" do
    scorecard = scorecards(:ruby_position_contacted_scorecard)
    added_event = events(:ruby_position_contacted_scorecard_added)
    author_account = accounts(:hiring_manager_account)
    added_event.update!(actor_account: author_account)
    candidate = scorecard.placement.candidate

    sign_out
    sign_in author_account

    assert_not_equal author_account.member.access_level, "admin"
    assert_difference "Scorecard.count", -1 do
      delete ats_scorecard_path(scorecard)
    end
    assert_response :redirect
    assert_redirected_to tab_ats_candidate_path(candidate, :scorecards)
    assert_nil Scorecard.find_by(id: scorecard.id)
  end

  test "should allow to destroy scorecard to admin" do
    scorecard = scorecards(:ruby_position_contacted_scorecard)
    added_event = events(:ruby_position_contacted_scorecard_added)
    author_account = accounts(:hiring_manager_account)
    added_event.update!(actor_account: author_account)
    candidate = scorecard.placement.candidate

    sign_out
    sign_in accounts(:admin_account)

    assert_difference "Scorecard.count", -1 do
      delete ats_scorecard_path(scorecard)
    end
    assert_response :redirect
    assert_redirected_to tab_ats_candidate_path(candidate, :scorecards)
    assert_nil Scorecard.find_by(id: scorecard.id)
  end

  test "should not allow to destroy scorecard to member that is neither a scorecard's author nor an admin" do
    scorecard = scorecards(:ruby_position_contacted_scorecard)
    signed_in_account = accounts(:employee_account)

    assert_not_equal signed_in_account.member.access_level, "admin"
    assert_not_equal scorecard.author.account, signed_in_account
    assert_no_difference "Scorecard.count" do
      delete ats_scorecard_path(scorecard)
    end

    assert_response :redirect
    assert_redirected_to "/"
    assert scorecard.reload
  end

  test "should render error if scorecard template was not destroyed" do
    sign_out
    sign_in accounts(:admin_account)
    scorecard = scorecards(:ruby_position_contacted_scorecard)

    scorecard_destroy_mock = Minitest::Mock.new
    scorecard_destroy_mock.expect(:call, Failure[:scorecard_not_destroyed, "error message"])

    Scorecards::Destroy.stub(:new, ->(_params) { scorecard_destroy_mock }) do
      err = assert_raises(RenderErrorExceptionForTests) do
        delete(ats_scorecard_path(scorecard))
      end

      err_info = JSON.parse(err.message)

      assert_equal err_info["message"], "error message"
      assert_equal err_info["status"], "unprocessable_entity"
    end
  end
end
