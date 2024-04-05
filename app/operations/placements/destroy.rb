# frozen_string_literal: true

class Placements::Destroy
  include Dry::Monads[:result, :try]

  include Dry::Initializer.define -> do
    option :placement, Types::Instance(Placement)
    option :actor_account, Types::Instance(Account)
  end

  def call
    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        placement.destroy!
      end
    end.to_result

    case result
    in Success(_)
      Success(placement)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:placement_invalid, placement.errors.full_messages.presence || e.to_s]
    end
  end
end
