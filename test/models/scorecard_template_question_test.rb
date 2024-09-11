# frozen_string_literal: true

require "test_helper"

class ScorecardTemplateQuestionTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  test "should create only one scorecard template question with the same list_index" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    scorecard_template = scorecard_templates(:ruby_position_sourced_scorecard_template)
    params = {
      scorecard_template:,
      list_index: 1,
      question: "What is your favorite programming language?"
    }

    assert_difference "ScorecardTemplateQuestion.count" do
      scorecard_template_question = ScorecardTemplateQuestions::Add.new(params:).call.value!

      assert_equal scorecard_template_question.list_index, params[:list_index]
      assert_equal scorecard_template_question.question, params[:question]
      assert_equal scorecard_template_question.scorecard_template_id, scorecard_template.id
    end

    e = nil
    assert_no_difference "ScorecardTemplateQuestion.count" do
      case ScorecardTemplateQuestions::Add.new(params:).call
      in Failure[:scorecard_template_question_not_unique, error]
        e = error
      end
    end
    assert_includes e, "idx_on_scorecard_template_id_list_index_"
  end
end
