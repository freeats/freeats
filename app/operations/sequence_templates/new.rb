# frozen_string_literal: true

class SequenceTemplates::New
  include Dry::Monads[:result]

  include Dry::Initializer.define -> do
    option :position_id, Types::Params::Integer
  end

  def call
    position = Position.find(position_id)
    params = {
      position:,
      name: position.name,
      subject: position.name
    }

    sequence_template = SequenceTemplate.new(params)

    SequenceTemplate::DEFAULT_STAGES.each do |stage|
      sequence_template.stages << SequenceTemplateStage.new(
        sequence_template:,
        position: stage[:position],
        delay_in_days: stage[:delay_in_days]
      )
    end

    Success(sequence_template)
  end
end
