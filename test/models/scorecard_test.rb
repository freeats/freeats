# frozen_string_literal: true

require "test_helper"

class ScorecardTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  test "should create scorecard" do
    params = {
      placement_id: placements(:sam_ruby_replied).id,
      score: "good",
      interviewer: "John Doe",
      title: "Ruby position contacted scorecard template scorecard",
      position_stage_id: position_stages(:ruby_position_replied).id,
      visible_to_interviewer: true
    }
    questions_params = [{ question: "How was the candidate's communication?", answer: "good" }]

    assert_difference "Scorecard.count" do
      scorecard = Scorecards::Add.new(params:, questions_params:).call.value!

      assert_equal scorecard.title, params[:title]
      assert_equal scorecard.position_stage_id, params[:position_stage_id]
      assert_equal [scorecard.visible_to_interviewer, params[:visible_to_interviewer]].uniq, [true]

      scorecard_questions = scorecard.scorecard_questions

      assert_equal [scorecard_questions.count, questions_params.count].uniq, [1]
      assert_equal scorecard_questions.map(&:question), questions_params.map { _1[:question] }
    end
  end

  test "should not create scorecard with invalid question" do
    params = {
      title: "Ruby position contacted scorecard template scorecard ",
      score: "good",
      interviewer: "John Doe",
      placement_id: placements(:sam_ruby_replied).id,
      position_stage_id: position_stages(:ruby_position_replied).id,
      visible_to_interviewer: true
    }
    questions_params = [{ question: "Invalid question" }]

    call_mock = Minitest::Mock.new
    call_mock.expect(:call, Failure[:scorecard_question_invalid, "Invalid question"])

    ScorecardQuestions::Add.stub :new, ->(_params) { call_mock } do
      assert_no_difference "Scorecard.count" do
        case Scorecards::Add.new(params:, questions_params:).call
        in Failure[:scorecard_question_invalid, error]

          assert_equal error, "Invalid question"
        end
      end
    end
  end

  test "should compose new scorecard" do
    scorecard_template = scorecard_templates(:ruby_position_contacted_scorecard_template)
    placement = placements(:sam_ruby_contacted)

    scorecard_new = Scorecards::New.new(scorecard_template:, placement:).call.value!

    assert_equal scorecard_new.title, "#{scorecard_template.title} scorecard"
    assert_equal scorecard_new.position_stage_id, scorecard_template.position_stage_id
    assert_equal scorecard_new.placement_id, placement.id
    assert_equal scorecard_new.scorecard_questions.map(&:question),
                 scorecard_template.scorecard_template_questions.pluck(:question)
    assert_equal [scorecard_new.visible_to_interviewer, scorecard_template.visible_to_interviewer].uniq,
                 [true]
  end
end
