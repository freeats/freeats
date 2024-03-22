# frozen_string_literal: true

class Candidates::Add
  include Dry::Monads[:result]

  # TODO: pass actor_account
  include Dry::Initializer.define -> do
    option :params, Types::Strict::Hash
  end

  def call
    candidate = Candidate.new
    candidate.assign_attributes(params)

    # TODO: adapt the below code when we have actor_user
    # if actor_user&.active_member? && !person.responsible_member
    #   candidate.recruiter_id = actor_user.member.id
    # end

    if candidate.valid?
      candidate.save!
      Success(candidate)
    else
      Failure[:candidate_invalid, candidate]
    end
  end
end
