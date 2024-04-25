# frozen_string_literal: true

class SequenceTemplates::Add
  include Dry::Monads[:result, :do]

  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash.schema(
      name: Types::Params::String,
      subject: Types::Params::String,
      position_id: Types::Params::Integer
    )
    option :stages_params, Types::Strict::Array.of(
      Types::Strict::Hash.schema(
        position: Types::Params::Integer,
        delay_in_days: Types::Params::Integer,
        body: Types::Params::String
      )
    )
  end

  def call
    # Dry options do not support hash with dynamic keys,
    # we remove them before calling the operation and re-define them here.
    stages_attributes = {}
    stages_params.map.with_index do |stage_params, index|
      stages_attributes[index] = stage_params
    end
    params[:stages_attributes] = stages_attributes

    sequence_template = SequenceTemplate.new
    sequence_template.assign_attributes(params)

    if sequence_template.stages.blank?
      return Failure[:sequence_template_invalid, "Sequence template must have at least one stage."]
    end

    yield save_sequence_template(sequence_template)

    Success(sequence_template)
  end

  private

  def save_sequence_template(sequence_template)
    sequence_template.save!
    Success()
  rescue ActiveRecord::RecordInvalid
    Failure[:sequence_template_invalid, sequence_template.errors.full_messages]
  end
end
