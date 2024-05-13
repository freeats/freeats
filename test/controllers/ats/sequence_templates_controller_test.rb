# frozen_string_literal: true

require "test_helper"

class ATS::SequenceTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:employee_account)
    sign_in @account
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
      assert_select("template", text: "Name has already been taken.")
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

  test "should update sequence_template and remove one stage" do
    sequence_template = sequence_templates(:golang_position_sequence_template)
    sequence_template_stage = sequence_template_stages(:golang_position_second_stage)

    stages_attributes = { "0" => {
      position: sequence_template_stage.position,
      delay_in_days: sequence_template_stage.delay_in_days,
      body: sequence_template_stage.body.to_s,
      id: sequence_template_stage.id,
      _destroy: true
    } }
    params = { sequence_template: {
      subject: "Subject",
      name: "Name",
      stages_attributes:
    } }

    assert_equal sequence_template.stages.size, 2
    assert_not_equal sequence_template.subject, params[:sequence_template][:subject]
    assert_not_equal sequence_template.name, params[:sequence_template][:name]

    assert_difference "SequenceTemplateStage.count" => -1 do
      assert_no_difference "SequenceTemplate.count" do
        patch ats_sequence_template_url(sequence_template, params:)
      end
    end
    assert_response :redirect

    sequence_template.reload

    assert_equal sequence_template.subject, params[:sequence_template][:subject]
    assert_equal sequence_template.name, params[:sequence_template][:name]
    assert_equal sequence_template.stages.size, 1
  end

  test "should not update sequence_template with stage without body" do
    sequence_template = sequence_templates(:golang_position_sequence_template)
    sequence_template_stage = sequence_template_stages(:golang_position_second_stage)

    stages_attributes = { "0" => {
      position: sequence_template_stage.position,
      delay_in_days: sequence_template_stage.delay_in_days,
      body: "",
      id: sequence_template_stage.id,
      _destroy: false
    } }
    params = { sequence_template: {
      subject: "Subject",
      name: "Name",
      stages_attributes:
    } }

    assert_no_difference "SequenceTemplate.count", "SequenceTemplateStage.count" do
      patch ats_sequence_template_url(sequence_template, params:)
    end

    assert_turbo_stream action: :replace, target: "alerts", status: :unprocessable_entity do
      assert_select("template", text: "Stages body can't be blank, remove empty stages or add text.")
    end
  end

  test "should replace first sequence template stage" do
    sequence_template = sequence_templates(:ruby_position_sequence_template)
    sequence_template_stage = sequence_template_stages(:ruby_position_first_stage)

    stages_attributes = {
      "0" => {
        position: sequence_template_stage.position,
        delay_in_days: 0,
        body: sequence_template_stage.body.to_s,
        id: sequence_template_stage.id,
        _destroy: true
      },
      "1" => {
        position: 1,
        delay_in_days: 55,
        body: "New body",
        _destroy: false
      }
    }
    params = { sequence_template: {
      subject: sequence_template.subject,
      name: sequence_template.name,
      stages_attributes:
    } }

    assert_equal sequence_template.stages.size, 1

    assert_no_difference "SequenceTemplate.count", "SequenceTemplateStage.count" do
      patch ats_sequence_template_url(sequence_template, params:)
    end

    assert_response :redirect

    sequence_template.reload

    assert_equal sequence_template.stages.size, 1

    new_first_stage = sequence_template.stages.first

    assert_not SequenceTemplateStage.exists?(sequence_template_stage.id)
    assert_equal new_first_stage.position, 1
    assert_nil new_first_stage.delay_in_days
  end

  test "should display setup_test modal" do
    sequence_template = sequence_templates(:golang_position_sequence_template)

    get setup_test_ats_sequence_template_path(sequence_template)

    assert_response :success

    doc = Nokogiri::HTML::Document.parse(response.body)

    assert_equal doc.at_css("#position").attr(:value), sequence_template.position.name
    assert_equal doc.at_css("#sender_first_name").attr(:value), @account.name.split.first
    assert_equal doc.at_css("#sender_calendar_url").attr(:value), @account.calendar_url
    assert_equal doc.at_css("#sender_linkedin_url").attr(:value), @account.linkedin_url
    assert_equal [doc.at_css("#female").attr(:value), @account.female.to_s], %w[female true]
  end

  test "should display test sequence_template" do
    sequence_template = sequence_templates(:golang_position_sequence_template)

    params = {
      position: sequence_template.position.name,
      sender_first_name: @account.name.split.first,
      sender_calendar_url: @account.calendar_url,
      sender_linkedin_url: @account.linkedin_url
    }
    get test_ats_sequence_template_path(sequence_template, params:)

    assert_response :success

    doc = Nokogiri::HTML::Document.parse(response.body)

    first_stage_body = doc.at_css(".card-body").text

    assert_includes first_stage_body, params[:position]
    assert_includes first_stage_body, params[:sender_first_name]
    assert_includes first_stage_body, params[:sender_calendar_url]
    assert_includes first_stage_body, params[:sender_linkedin_url]
  end
end
