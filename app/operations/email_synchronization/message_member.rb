# frozen_string_literal: true

class EmailSynchronization::MessageMember < ApplicationOperation
  option :field, Types::Symbol.enum(:from, :to, :cc, :bcc)
  option :member, Types::Instance(Member)
end
