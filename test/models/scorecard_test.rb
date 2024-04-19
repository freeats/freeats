# frozen_string_literal: true

require "test_helper"

class ScorecardTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  test "should create scorecard" do
    actor_account = accounts(:admin_account)

    params = {
      placement_id: placements(:sam_ruby_replied).id,
      score: "good",
      interviewer: "John Doe",
      title: "Ruby position contacted scorecard template scorecard",
      position_stage_id: position_stages(:ruby_position_replied).id,
      visible_to_interviewer: true
    }
    questions_params = [{ question: "How was the candidate's communication?", answer: "good" }]

    assert_difference "Scorecard.count" => 1, "Event.count" => 1 do
      scorecard = Scorecards::Add.new(params:, questions_params:, actor_account:).call.value!

      assert_equal scorecard.title, params[:title]
      assert_equal scorecard.position_stage_id, params[:position_stage_id]
      assert_equal [scorecard.visible_to_interviewer, params[:visible_to_interviewer]].uniq, [true]

      scorecard_questions = scorecard.scorecard_questions

      assert_equal [scorecard_questions.count, questions_params.count].uniq, [1]
      assert_equal scorecard_questions.map(&:question), questions_params.map { _1[:question] }

      event = Event.last

      assert_equal event.type, "scorecard_added"
      assert_equal event.actor_account_id, actor_account.id
      assert_equal event.eventable_id, scorecard.id
      assert_equal event.eventable_type, "Scorecard"
    end
  end

  test "should not create scorecard with invalid question" do
    actor_account = accounts(:admin_account)

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
        case Scorecards::Add.new(params:, questions_params:, actor_account:).call
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

  test "should change scorecard and scorecard questions" do
    actor_account = accounts(:admin_account)
    scorecard = scorecards(:ruby_position_contacted_scorecard)
    scorecard_questions = scorecard.scorecard_questions

    assert_nil scorecard.summary
    assert_predicate scorecard_questions, :present?

    params = {
      interviewer: "John Doe",
      score: "relevant",
      summary: "Acceptable candidate"
    }
    questions_params = scorecard_questions.map do |question|
      { id: question.id, answer: "Answer to question ##{question.list_index}" }
    end

    assert_difference "Event.count" => 1 do
      scorecard = Scorecards::Change.new(params:, questions_params:, scorecard:, actor_account:).call.value!

      assert_equal scorecard.interviewer, params[:interviewer]
      assert_equal scorecard.score, params[:score]
      assert_match params[:summary], scorecard.summary.body.to_s

      scorecard.scorecard_questions.each do |question|
        answer = questions_params.find { _1[:id] == question.id }[:answer]

        assert_match answer, question.answer.body.to_s
      end

      event = Event.last

      assert_equal event.type, "scorecard_updated"
      assert_equal event.eventable_id, scorecard.id
      assert_equal event.eventable_type, "Scorecard"
      assert_equal event.actor_account_id, actor_account.id
    end
  end
end
