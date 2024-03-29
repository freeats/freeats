# frozen_string_literal: true

class Positions::Add
  include Dry::Monads[:result, :do, :try]

  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash.schema(
      name: Types::Strict::String
    )
    option :actor_account, Types::Instance(Account)
  end

  def call
    auto_assigned_params = {
      recruiter_id: actor_account.member.id
    }
    position = Position.new(params.merge(auto_assigned_params))

    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        position.save!

        Position::DEFAULT_STAGES.each.with_index(1) do |name, index|
          params = { position:, name:, list_index: index }
          yield PositionStages::Add.new(params:).call
        end
      end

      position
    end.to_result

    case result
    in Success(position)
      Success(position.reload)
    in Failure[ActiveRecord::RecordInvalid, e]
      Failure[:position_invalid, e]
    end
  end
end
