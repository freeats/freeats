# frozen_string_literal: true

class Candidates::Interviews::Resolve
  include Dry::Monads[:result, :do]

  include Dry::Initializer.define -> do
    option :status,
           Types::Strict::String.enum(*::Candidate::Interview::RESOLVED_STATUSES)
    option :scheduled_event, Types::Instance(::Candidate::Interview)
    option :actor_account, Types::Instance(Account)
  end

  def call
    return Failure(:not_scheduled_event_type) unless scheduled_event.scheduled_event?
    return Failure(:already_resolved) if scheduled_event.find_resolved_event.present?

    params = {
      type: :candidate_interview_resolved,
      eventable: scheduled_event.eventable,
      actor_account:,
      properties: {
        status:,
        pair_event_id: scheduled_event.id
      }
    }

    yield Events::Add.new(params:).call
    # TODO: create task on passed and failed status.

    Success()
  end
end
