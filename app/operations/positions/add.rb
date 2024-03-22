# frozen_string_literal: true

class Positions::Add
  include Dry::Monads[:result, :do]

  # TODO: pass actor_account
  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash
  end

  def call
    position = Position.new(params)

    return Failure[:position_invalid, position] unless position.valid?

    ActiveRecord::Base.transaction do
      position.save!

      Position::DEFAULT_STAGES.each.with_index(1) do |name, index|
        params = { position:, name:, list_index: index }
        yield PositionStages::Add.new(params:).call
      end
    end

    Success(position.reload)
  end
end
