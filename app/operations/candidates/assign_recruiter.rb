# frozen_string_literal: true

class Candidates::AssignRecruiter
  include Dry::Monads[:result, :try]

  # TODO: pass actor_account
  include Dry::Initializer.define -> do
    option :candidate, Types::Instance(Candidate)
    option :recruiter_id, ->(v) { v.presence&.to_i }
  end

  def call
    candidate.recruiter_id = recruiter_id

    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        candidate.save!
        # TODO: create events
      end
    end.to_result

    case result
    in Success(_)
      Success(candidate.reload)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:recruiter_invalid, candidate.errors.full_messages.presence || e.to_s]
    end
  end
end
