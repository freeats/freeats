# frozen_string_literal: true

class Positions::ChangeStages < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :position, Types::Instance(Position)
  option :stages_attributes, Types::Strict::Hash
  option :actor_account, Types::Instance(Account)

  def call
    new_and_changed_stages = stages_attributes.values.filter { _1[:name].present? }
    new_stages, changed_stages = new_and_changed_stages.partition { _1[:id].nil? }

    last_stage_list_index = position.stages.pluck(:list_index).max if new_stages.present?

    ActiveRecord::Base.transaction do
      changed_stages.each do |changed_stage|
        yield PositionStages::Change.new(params: changed_stage, actor_account:).call
      end

      new_stages.each.with_index do |new_stage, index|
        yield PositionStages::Add.new(
          params: {
            position:,
            name: new_stage[:name],
            list_index: last_stage_list_index + index
          },
          actor_account:
        ).call
      end
    end

    Success(position.reload)
  end
end
