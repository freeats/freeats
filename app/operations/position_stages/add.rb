# frozen_string_literal: true

class PositionStages::Add
  include Dry::Monads[:result]

  # TODO: pass actor_account
  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash
  end

  def call
    position_stage = PositionStage.new(params)

    if position_stage.valid?
      position_stage.save!
      Success(position_stage)
    else
      Failure[:position_stage_invalid, position_stage]
    end
  end
end
