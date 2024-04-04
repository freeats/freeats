# frozen_string_literal: true

class PositionStages::Change
  include Dry::Monads[:result, :try]

  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash.schema(
      id: Types::Params::Integer,
      name: Types::Params::String
    )
  end

  def call
    position_stage = PositionStage.find(params[:id])
    position_stage.assign_attributes(params)

    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        position_stage.save!
      end

      nil
    end.to_result

    case result
    in Success(_)
      Success(position_stage)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:position_stage_invalid, position_stage.errors.full_messages.presence || e.to_s]
    end
  end
end
