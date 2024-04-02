# frozen_string_literal: true

require "test_helper"

class ScorecardTemplateTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  test "should create only one scorecard template" do
    position_stage = position_stages(:ruby_position_replied)

    assert_difference "ScorecardTemplate.count" do
      scorecard_template = ScorecardTemplates::Add.new(position_stage:).call.value!

      assert_equal scorecard_template.title, "Replied stage scorecard template"
    end

    error = nil
    assert_no_difference "ScorecardTemplate.count" do
      case ScorecardTemplates::Add.new(position_stage:).call
      in Failure[:scorecard_template_not_unique, e]
        error = e
      end
    end

    assert_includes error.to_s, "index_scorecard_templates_on_position_stage_id"
  end

  test "should destroy questions when destroying scorecard template" do
    scorecard_template = scorecard_templates(:ruby_position_contacted)
    scorecard_template_question = scorecard_template_questions(:ruby_position_contacted_first_question)

    assert_equal scorecard_template.scorecard_template_questions.count, 1

    scorecard_template.destroy

    assert_nil ScorecardTemplateQuestion.find_by(id: scorecard_template_question.id)
  end
end
