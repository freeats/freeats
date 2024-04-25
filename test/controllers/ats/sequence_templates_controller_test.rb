# frozen_string_literal: true

require "test_helper"

class ATS::SequenceTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in accounts(:employee_account)
  end

  test "should compose the new sequence_template" do
    position = positions(:ruby_position)

    assert_no_difference "SequenceTemplate.count" do
      get new_ats_sequence_template_path(position_id: position.id)
    end

    assert_response :success

    doc = Nokogiri::HTML::Document.parse(response.body)

    assert_equal doc.at_css("#sequence_template_position_id").attr(:value), position.id.to_s
  end

  test "should create only one sequence_template with the same name" do
    position = positions(:ruby_position)

    stages_attributes = { "0" => { position: 1, delay_in_days: 0, body: "Body1" } }
    params = { sequence_template: {
      subject: "Subject",
      name: "Name",
      position_id: position.id,
      stages_attributes:
    } }

    assert_difference "SequenceTemplate.count" => 1, "SequenceTemplateStage.count" => 1 do
      post ats_sequence_templates_url, params:
    end
    assert_response :redirect

    sequence_template = SequenceTemplate.last

    assert_equal sequence_template.subject, params[:sequence_template][:subject]
    assert_equal sequence_template.name, params[:sequence_template][:name]
    assert_equal sequence_template.position_id, position.id
    assert_equal sequence_template.stages.size, 1

    stage = sequence_template.stages.first

    assert_equal stage.position, stages_attributes["0"][:position]
    assert_nil stage.delay_in_days
    assert_equal stage.body.to_s,
                 "<div class=\"trix-content\">\n  #{stages_attributes['0'][:body]}\n</div>\n"

    assert_no_difference "SequenceTemplate.count", "SequenceTemplateStage.count" do
      post ats_sequence_templates_url, params:
    end

    assert_turbo_stream action: :replace, target: "alerts", status: :unprocessable_entity do
      assert_select("template", text: "Name has already been taken")
    end
  end

  test "should not create sequence_template without stages" do
    position = positions(:ruby_position)

    params = { sequence_template: {
      subject: "Subject",
      name: "Name",
      position_id: position.id
    } }

    assert_no_difference "SequenceTemplate.count", "SequenceTemplateStage.count" do
      post ats_sequence_templates_url, params:
    end

    assert_turbo_stream action: :replace, target: "alerts", status: :unprocessable_entity do
      assert_select("template", text: "Sequence template must have at least one stage.")
    end
  end

  test "should not create sequence_template with stage without body" do
    position = positions(:ruby_position)

    params = { sequence_template: {
      subject: "Subject",
      name: "Name",
      position_id: position.id,
      stages_attributes: { "0": { position: 1, delay_in_days: 0, body: "" } }
    } }

    assert_no_difference "SequenceTemplate.count", "SequenceTemplateStage.count" do
      post ats_sequence_templates_url, params:
    end

    assert_turbo_stream action: :replace, target: "alerts", status: :unprocessable_entity do
      assert_select("template", text: "Stages body can't be blank, remove empty stages or add text.")
    end
  end

  test "should get show" do
    sequence_template = sequence_templates(:golang_position_sequence_template)

    get ats_sequence_template_url(sequence_template)

    assert_response :success
  end

  test "should archive sequence_template" do
    sequence_template = sequence_templates(:golang_position_sequence_template)

    assert_not sequence_template.archived

    patch archive_ats_sequence_template_url(sequence_template)

    assert_response :success
    assert sequence_template.reload.archived
  end
end
