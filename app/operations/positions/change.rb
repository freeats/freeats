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
    old_stages = position.stages.pluck(:name)
    new_stages =
      params
      .delete(:stages_attributes)
      &.map { _2.fetch(:name, "") }
      &.filter(&:present?) || []

    new_stages -= old_stages

    last_stage_list_index = position.stages.where.not(name: :hired).map(&:list_index).max

    position.assign_attributes(params)

    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        position.save!

        new_stages.each.with_index(1) do |new_stage, index|
          yield PositionStages::Add.new(
            params: {
              position:,
              name: new_stage,
              list_index: last_stage_list_index + index
            }
          ).call
        end
        # TODO: create events
      end
      nil
    end.to_result

    case result
    in Success(_)
      Success(position.reload)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:position_invalid, position.errors.full_messages.presence || e]
    in Failure[:position_stage_invalid, _]
      result
    end
  end
end
