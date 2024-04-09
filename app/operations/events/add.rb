# frozen_string_literal: true

class Events::Add
  include Dry::Monads[:result, :try]

  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash.schema(
      actor_account: Types::Instance(Account),
      eventable: Types::Instance(ApplicationRecord),
      type: Types::Symbol.enum(*Event.types.keys.map(&:to_sym)),
      changed_to?: Types::Strict::Integer | Types::Strict::String | Types::Strict::Array,
      changed_from?: Types::Strict::Integer | Types::Strict::String | Types::Strict::Array,
      changed_field?: Types::Strict::Symbol,
      properties?: Types::Strict::Hash
    )
  end

  def call
    event = Event.new(params)

    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        event.save!
      end
    end.to_result

    case result
    in Success(_)
      Success(event)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:event_invalid, event.errors.full_messages.presence || e.to_s]
    end
  end
end
