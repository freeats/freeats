# frozen_string_literal: true

class EmailSynchronization::MessageMember
  include Dry::Initializer.define -> do
    option :field, Types::Symbol.enum(:from, :to)
    option :member, Types::Instance(Member)
  end
end
