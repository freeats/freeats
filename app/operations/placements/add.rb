# frozen_string_literal: true

class Placements::Add
  include Dry::Monads[:result]

  # TODO: pass actor_account
  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash
    option :position, Types.Instance(Position)
  end

  def call
    # Stages already ordered by list_index.
    params[:position_stage] = position.stages.first

    placement = Placement.new
    placement.assign_attributes(**params, position:)

    if placement.valid?
      placement.save!
      Success(placement)
    else
      Failure[:placement_invalid, placement]
    end
  end
end
