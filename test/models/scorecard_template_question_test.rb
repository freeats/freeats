# frozen_string_literal: true

require "test_helper"

class ScorecardTemplateQuestionTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  test "should create only one scorecard template question with the same list_index" do
    scorecard_template = scorecard_templates(:ruby_position_sourced)
    params = {
      scorecard_template:,
      list_index: 1,
      question: "What is your favorite programming language?"
    }

    assert_difference "ScorecardTemplateQuestion.count" do
      ScorecardTemplateQuestions::Add.new(params:).call.value!
    end

    e = nil
    assert_no_difference "ScorecardTemplateQuestion.count" do
      case ScorecardTemplateQuestions::Add.new(params:).call
      in Failure[:scorecard_template_question_not_unique, error]
        e = error
      end
    end
    assert_includes e.to_s, "idx_on_scorecard_template_id_list_index_"
  end
end
