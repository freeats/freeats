# frozen_string_literal: true

require "test_helper"

class ScorecardTemplateTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  test "should create only one scorecard template" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    position_stage = position_stages(:ruby_position_hired)
    actor_account = accounts(:admin_account)

    params = {
      title: "Replied stage scorecard template",
      position_stage_id: position_stage.id
    }
    questions_params = [{ question: "How was the candidate's communication?" }]

    assert_difference "ScorecardTemplate.count" => 1, "Event.count" => 1 do
      scorecard_template =
        ScorecardTemplates::Add.new(params:, questions_params:, actor_account:).call.value!

      assert_equal scorecard_template.title, "Replied stage scorecard template"
      assert_equal scorecard_template.position_stage_id, position_stage.id

      scorecard_template_questions = scorecard_template.scorecard_template_questions

      assert_equal [scorecard_template_questions.count, questions_params.count].uniq, [1]
      assert_equal scorecard_template_questions.map(&:question), questions_params.map { _1[:question] }

      event = Event.last

      assert_equal event.actor_account_id, actor_account.id
      assert_equal event.type, "scorecard_template_added"
      assert_equal event.eventable_id, scorecard_template.id
    end

    assert_no_difference "ScorecardTemplate.count" do
      case ScorecardTemplates::Add.new(params:, questions_params:, actor_account:).call
      in Failure[:scorecard_template_not_unique, e]
        assert_includes e, "index_scorecard_templates_on_position_stage_id"
      end
    end
  end

  test "should destroy questions when destroying scorecard template" do
    scorecard_template = scorecard_templates(:ruby_position_contacted_scorecard_template)
    scorecard_template_question =
      scorecard_template_questions(:ruby_position_contacted_first_scorecard_template_question)

    assert_equal scorecard_template.scorecard_template_questions.count, 1

    scorecard_template.destroy

    assert_nil ScorecardTemplateQuestion.find_by(id: scorecard_template_question.id)
  end

  test "should bubble up exception if event creation raises exception" do
    ActsAsTenant.current_tenant = tenants(:toughbyte_tenant)
    position_stage = position_stages(:ruby_position_hired)
    actor_account = accounts(:admin_account)

    params = {
      title: "Replied stage scorecard template",
      position_stage_id: position_stage.id
    }

    Event.stub :create!, ->(_params) { raise ActiveRecord::RecordInvalid } do
      assert_raises(ActiveRecord::RecordInvalid) do
        ScorecardTemplates::Add.new(params:, questions_params: [], actor_account:).call
      end
    end
  end

  test "should compose new scorecard template" do
    position_stage_id = position_stages(:ruby_position_replied).id

    scorecard_template_new = ScorecardTemplates::New.new(position_stage_id:).call.value!

    assert_equal scorecard_template_new.title, "Replied stage scorecard template"
    assert_equal scorecard_template_new.position_stage_id, position_stage_id
  end
end
