# frozen_string_literal: true

class ATS::SequenceTemplatesController < ApplicationController
  before_action :authorize!
  before_action :set_sequence_template, only: %i[show archive edit update]

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
    # TODO: implement this action
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
end
