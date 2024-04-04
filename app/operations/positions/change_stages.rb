# frozen_string_literal: true

class Positions::ChangeStages
  include Dry::Monads[:result, :do]

  include Dry::Initializer.define -> do
    option :position, Types::Instance(Position)
    option :stages_attributes, Types::Strict::Hash
  end

  def call
    new_and_changed_stages = stages_attributes.values.filter { _1[:name].present? }
    new_stages, changed_stages = new_and_changed_stages.partition { _1[:id].nil? }

    last_stage_list_index = position.stages.pluck(:list_index).max

    ActiveRecord::Base.transaction do
      changed_stages.each do |changed_stage|
        yield PositionStages::Change.new(params: changed_stage).call
      end

      new_stages.each.with_index do |new_stage, index|
        yield PositionStages::Add.new(
          params: {
            position:,
            name: new_stage[:name],
            list_index: last_stage_list_index + index
          }
        ).call
      end
    end

    Success(position)
  end
end
