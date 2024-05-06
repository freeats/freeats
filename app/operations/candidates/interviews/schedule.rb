# frozen_string_literal: true

class Candidates::Interviews::Schedule
  include Dry::Monads[:result, :do]

  include Dry::Initializer.define -> do
    option :candidate, Types::Instance(Candidate)
    option :selected_time, Types::Strict::DateTime
    option :actor_account, Types::Instance(Account)
  end

  def call
    params = {
      actor_account:,
      type: :candidate_interview_scheduled,
      eventable: candidate,
      properties: {
        scheduled_for: selected_time.rfc3339
      }
    }

    yield Events::Add.new(params:).call

    Success()
  end
end
