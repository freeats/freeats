# frozen_string_literal: true

class Candidates::AlternativeNames::Change < ApplicationOperation
  include Dry::Monads[:result, :do, :try]

  option :candidate, Types::Instance(Candidate)
  option :actor_account, Types::Instance(Account)
  option :alternative_names, Types::Strict::Array.of(
    Types::Strict::Hash.schema(
      name: Types::Strict::String
    )
  )

  def call
    old_alternative_names = candidate.candidate_alternative_names.pluck(:name)
    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        candidate.candidate_alternative_names.destroy_all

        alternative_names.each do |alternative_name|
          yield Candidates::AlternativeNames::Add.new(
            candidate:,
            alternative_name: alternative_name[:name]
          ).call
        end

        Events::AddChangedEvent.new(
          eventable: candidate,
          changed_field: "alternative_names",
          field_type: :plural,
          old_value: old_alternative_names,
          new_value: candidate.candidate_alternative_names.pluck(:name),
          actor_account:
        ).call

        nil
      end
    end.to_result

    case result
    in Success(_)
      Success(candidate.candidate_alternative_names)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:alternative_name_invalid, candidate.errors.full_messages.presence || e.to_s]
    end
  end
end
