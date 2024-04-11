# frozen_string_literal: true

class Candidates::AlternativeNames::Change
  include Dry::Monads[:result, :do, :try]

  include Dry::Initializer.define -> do
    option :candidate, Types::Instance(Candidate)
    option :alternative_names, Types::Strict::Array.of(
      Types::Strict::Hash.schema(
        name: Types::Strict::String
      )
    )
  end

  def call
    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        candidate.candidate_alternative_names.destroy_all

        alternative_names.each do |alternative_name|
          yield Candidates::AlternativeNames::Add.new(
            candidate:,
            alternative_name: alternative_name[:name]
          ).call
        end

        # TODO: create events

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
