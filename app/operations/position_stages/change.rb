# frozen_string_literal: true

class PositionStages::Change < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :params, Types::Strict::Hash.schema(
    id: Types::Params::Integer,
    name: Types::Params::String
  )
  option :actor_account, Types::Instance(Account)

  def call
    position_stage = PositionStage.find(params[:id])
    old_name = position_stage.name

    position_stage.name = params[:name]

    ActiveRecord::Base.transaction do
      yield save_position_stage(position_stage)
      yield add_event(position_stage:, actor_account:, old_name:)
    end

    Success()
  end

  private

  def save_position_stage(position_stage)
    position_stage.save!

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:position_stage_invalid, position_stage.errors.full_messages.presence || e.to_s]
  end

  def add_event(position_stage:, actor_account:, old_name:)
    return Success() if old_name == position_stage.name

    position_stage_changed_params = {
      actor_account:,
      type: :position_stage_changed,
      eventable: position_stage,
      changed_field: :name,
      changed_from: old_name,
      changed_to: position_stage.name
    }

    yield Events::Add.new(params: position_stage_changed_params).call

    Success()
  end
end
