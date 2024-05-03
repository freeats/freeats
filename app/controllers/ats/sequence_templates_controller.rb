# frozen_string_literal: true

class ATS::SequenceTemplatesController < ApplicationController
  before_action :set_sequence_template, only: %i[show archive edit update setup_test test]
  before_action :authorize!, only: %i[create new]
  before_action -> { authorize!(@sequence_template) },
                only: %i[show edit update setup_test test archive]

  include Dry::Monads[:result]

  layout "ats/application"

  def show; end

  def new
    case SequenceTemplates::New.new(position_id: params[:position_id]).call
    in Success(sequence_template)
      @sequence_template = sequence_template
    end
  end

  def edit; end

  def create
    case SequenceTemplates::Add.new(params: sequence_template_params, stages_params:).call
    in Success(sequence_template)
      redirect_to ats_sequence_template_path(sequence_template)
    in Failure[:sequence_template_invalid, error]
      render_turbo_stream([], error:, status: :unprocessable_entity)
    end
  end

  def update
    case SequenceTemplates::Change.new(
      sequence_template: @sequence_template,
      params: sequence_template_params,
      stages_params:
    ).call
    in Success(sequence_template)
      redirect_to ats_sequence_template_path(sequence_template)
    in Failure[:sequence_template_invalid, error]
      render_turbo_stream([], error:, status: :unprocessable_entity)
    end
  end

  def setup_test
    partial_name = "test_sequence_template_modal"
    @sequence_template_variables = @sequence_template.present_variables
    @defaults =
      LiquidTemplate.extract_attributes_from(
        current_account:,
        position: @sequence_template.position
      )

    render(
      partial: partial_name,
      layout: "modal",
      locals: {
        modal_id: partial_name.dasherize,
        form_options: {
          url: test_ats_sequence_template_path(@sequence_template),
          method: :get,
          html: { target: "_blank" },
          data: {
            turbo: false
          }
        },
        modal_size: "modal-lg"
      }
    )
  end

  def test
    @parameters = test_sequence_template_params(@sequence_template.present_variables)

    render "_test_show"
  end

  def archive
    # TODO: uncomment logic with sequences after adding sequences.
    if @sequence_template.update!(archived: true)
      # running_sequences_count = @sequence_template.sequences.where(status: :running).count

      notice = [@sequence_template.name, "has_been_successfully archived."]
      # if running_sequences_count.positive?
      #   notice <<
      #     "There #{'is'.pluralize(running_sequences_count)} still #{running_sequences_count}
      #     #{'sequence'.pluralize(running_sequences_count)} running."
      # end

      render_turbo_stream(
        [turbo_stream.replace("turbo_ats_email_templates_info", partial: "info")],
        notice: notice.join(" ")
      )
      return
    end
    render_error @sequence_template.errors.full_messages, status: :unprocessable_entity
  end

  private

  def set_sequence_template
    @sequence_template = SequenceTemplate.find(params[:id])
  end

  def sequence_template_params
    params
      .require(:sequence_template)
      .permit(:name, :subject, :position_id)
      .to_h
      .deep_symbolize_keys
  end

  def stages_params
    params
      .require(:sequence_template)
      .permit(stages_attributes: %i[id position delay_in_days body _destroy])
      .[](:stages_attributes)
      .to_h
      .deep_symbolize_keys
      .values
  end

  def test_sequence_template_params(variables)
    variables.index_with do |variable|
      result = params[variable].presence
      result == "false" ? false : result
    end
  end
end
