# frozen_string_literal: true

class Placements::ChangeStage
  include Dry::Monads[:result, :try]

  include Dry::Initializer.define -> do
    option :new_stage, Types::Strict::String
    option :placement, Types::Instance(Placement)
    option :actor_account, Types::Instance(Account)
  end

  def call
    placement.position_stage = placement.position.stages.find_by(name: new_stage)

    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        placement.save!
        # TODO: create events
      end
    end.to_result

    case result
    in Success(_)
      Success(placement.reload)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:placement_invalid, placement.errors.full_messages.presence || e.to_s]
    end
  end
end
