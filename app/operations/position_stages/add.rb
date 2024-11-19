# frozen_string_literal: true

class PositionStages::Add < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :params, Types::Strict::Hash.schema(
    list_index: Types::Params::Integer,
    name: Types::Params::String,
    position: Types::Instance(Position)
  )
  option :actor_account, Types::Instance(Account)

  def call
    position_stage = PositionStage.new(params)

    ActiveRecord::Base.transaction do
      yield save_position_stage(position_stage)
      add_event(position_stage:, actor_account:)
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

  def add_event(position_stage:, actor_account:)
    params = {
      actor_account:,
      type: :position_stage_added,
      eventable: position_stage,
      properties: { name: position_stage.name }
    }
    Event.create!(params)
  end
end
