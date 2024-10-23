# frozen_string_literal: true

class Events::Add < ApplicationOperation
  include Dry::Monads[:result, :try]

  option :params, Types::Strict::Hash.schema(
    actor_account: Types::Instance(Account).optional,
    eventable: Types::Instance(ApplicationRecord) | Types::Instance(ActiveStorage::Attachment),
    type: Types::Symbol.enum(*Event.types.keys.map(&:to_sym)),
    changed_to?: Types::Strict::Integer | Types::Strict::String |
                  Types::Strict::Bool | Types::Strict::Date |
                  Types::Strict::Array.optional,
    changed_from?: Types::Strict::Integer | Types::Strict::String |
                    Types::Strict::Bool | Types::Strict::Date |
                    Types::Strict::Array.optional,
    changed_field?: Types::Strict::Symbol | Types::Strict::String,
    properties?: Types::Strict::Hash.optional,
    performed_at?: Types::Strict::DateTime.optional
  )

  def call
    params[:performed_at] ||= Time.zone.now
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
