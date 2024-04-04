# frozen_string_literal: true

class Positions::Change
  include Dry::Monads[:result, :do, :try]

  include Dry::Initializer.define -> do
    option :position, Types::Instance(Position)
    option :params, Types::Strict::Hash.schema(
      name?: Types::Strict::String,
      recruiter_id?: Types::Strict::String.optional,
      collaborator_ids?: Types::Strict::Array.of(Types::Strict::String.optional),
      description?: Types::Strict::String,
      stages_attributes?: Types::Strict::Hash
    ).strict
    option :actor_account, Types::Instance(Account)
  end

  def call
    stages_attributes = params.delete(:stages_attributes)

    position.assign_attributes(params)

    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        position.save!

        if stages_attributes.present?
          yield Positions::ChangeStages.new(position:, stages_attributes:).call
        end

        # TODO: create events
      end
      nil
    end.to_result

    case result
    in Success(_)
      Success(position.reload)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:position_invalid, position.errors.full_messages.presence || e.to_s]
    in Failure[:position_stage_invalid, _]
      result
    end
  end
end
