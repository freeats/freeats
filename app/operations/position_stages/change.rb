# frozen_string_literal: true

class PositionStages::Change
  include Dry::Monads[:result]

  # TODO: pass actor_account
  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash
    option :position_stage, Types.Instance(PositionStage)
  end

  def call
    position_stage.assign_attributes(params)

    if position_stage.valid?
      position_stage.save!
      Success(position_stage)
    else
      Failure[:position_stage_invalid, position_stage]
    end
  end
end
