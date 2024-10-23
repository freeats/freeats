# frozen_string_literal: true

class Candidates::AlternativeNames::Add < ApplicationOperation
  include Dry::Monads[:result, :try]

  option :candidate, Types::Instance(Candidate)
  option :alternative_name, Types::Strict::String

  def call
    result = Try[ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique] do
      candidate.candidate_alternative_names.create!(
        name: alternative_name
      )

      nil
    end.to_result

    case result
    in Success(_)
      Success(candidate.candidate_alternative_names)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:alternative_name_invalid, candidate.errors.full_messages.presence || e.to_s]
    in Failure[ActiveRecord::RecordNotUnique => e]
      Failure[:alternative_name_not_unique, candidate.errors.full_messages.presence || e.to_s]
    end
  end
end
