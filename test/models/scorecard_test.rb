# frozen_string_literal: true

require "test_helper"

class ScorecardTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  test "should create scorecard" do
    params = {
      placement: placements(:sam_ruby),
      score: "good",
      interviewer: "John Doe"
    }
    scorecard_template = scorecard_templates(:ruby_position_contacted)

    assert_equal scorecard_template.visible_to_interviewer, true
    assert_equal scorecard_template.scorecard_template_questions.count, 1

    assert_difference "Scorecard.count" do
      scorecard = Scorecards::Add.new(params:, scorecard_template:).call.value!

      assert_equal scorecard.title, scorecard_template.title
      assert_equal scorecard.position_stage_id, scorecard_template.position_stage_id
      assert_equal scorecard.visible_to_interviewer, scorecard_template.visible_to_interviewer

      scorecard_questions = scorecard.scorecard_questions
      scorecard_template_questions = scorecard_template.scorecard_template_questions

      assert_equal scorecard_questions.count, scorecard_template_questions.count
      assert_equal scorecard_questions.map(&:question), scorecard_template_questions.map(&:question)
    end
  end

  test "should not create scorecard with invalid params" do
    params = {
      placement: Placement.new(position: positions(:ruby_position)),
      score: "good",
      interviewer: "John Doe"
    }
    scorecard_template = scorecard_templates(:ruby_position_contacted)

    e = nil
    assert_no_difference "Scorecard.count" do
      case Scorecards::Add.new(params:, scorecard_template:).call
      in Failure[:scorecard_invalid, error]
        e = error
      end
    end

    assert_includes e, "null value in column \"placement_id\""
  end

  test "should not create scorecard with invalid question" do
    params = {
      placement: placements(:sam_ruby),
      score: "good",
      interviewer: "John Doe"
    }
    scorecard_template = scorecard_templates(:ruby_position_contacted)

    call_mock = Minitest::Mock.new
    call_mock.expect(:call, Failure[:scorecard_question_invalid, "Invalid question"])

    e = nil

    ScorecardQuestions::Add.stub :new, ->(_params) { call_mock } do
      assert_no_difference "Scorecard.count" do
        case Scorecards::Add.new(params:, scorecard_template:).call
        in Failure[:scorecard_question_invalid, error]
          e = error
        end
      end
    end

    assert_equal e, "Invalid question"
  end
end
