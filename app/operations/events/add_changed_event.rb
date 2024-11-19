# frozen_string_literal: true

class Events::AddChangedEvent < ApplicationOperation
  include Dry::Monads[:result]

  option :changed_field, Types::Strict::Symbol | Types::Strict::String
  option :eventable, Types::Instance(ApplicationRecord)
  option :performed_at, Types::Strict::DateTime.optional, optional: true
  option :field_type, Types::Symbol.enum(:singular, :plural).optional,
         default: proc { :singular }
  option :old_value,
         Types::Strict::Integer | Types::Strict::String |
         Types::Strict::Bool | Types::Strict::Date |
         Types::Strict::Array.optional,
         optional: true
  option :new_value,
         Types::Strict::Integer | Types::Strict::String |
         Types::Strict::Bool | Types::Strict::Date |
         Types::Strict::Array.optional,
         optional: true
  option :actor_account, Types::Instance(Account).optional, optional: true
  option :properties, Types::Strict::Hash.optional, default: proc { {} }

  def call
    changed_from =
      if field_type == :plural
        (old_value || []).sort
      else
        old_value
      end

    changed_to =
      if field_type == :plural
        (new_value || []).sort
      else
        new_value
      end

    # CV files may have the same names.
    return Failure(:to_equals_from) if changed_from == changed_to && changed_field != "cv"

    class_name = eventable.class.name.downcase
    type = Event.types["#{class_name}_changed"].to_sym
    created_event =
      Event.create!(
        eventable:,
        changed_from:,
        changed_to:,
        changed_field:,
        properties:,
        type:,
        actor_account:,
        performed_at: performed_at || Time.zone.now
      )
    Success(created_event)
  end
end
