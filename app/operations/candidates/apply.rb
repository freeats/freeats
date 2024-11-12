# frozen_string_literal: true

class Candidates::Apply < ApplicationOperation
  include Dry::Monads[:result, :do, :try]

  option :actor_account, Types::Instance(Account).optional
  option :params, Types::Strict::Hash.schema(
    file: Types::Instance(ActionDispatch::Http::UploadedFile),
    full_name: Types::Strict::String,
    email: Types::Strict::String
  )
  option :position_id, Types::Coercible::Integer

  def call
    candidate_email_addresses =
      [{
        address: params[:email],
        status: "current",
        source: "other",
        type: "personal",
        created_via: "applied"
      }]
    candidate_params = { full_name: params[:full_name], emails: candidate_email_addresses }
    file = params[:file]

    position = Position.find(position_id)
    recruiter = position.recruiter
    return Failure(:no_active_recruiter) if recruiter.blank? || recruiter.inactive?

    candidate = Candidate.transaction do
      candidate = yield Candidates::Add.new(params: candidate_params, actor_account:).call

      placement = yield Placements::Add.new(
        params: { candidate_id: candidate.id, position_id: },
        actor_account:
      ).call

      yield Placements::ChangeStage.new(new_stage: "Replied", placement:, actor_account:).call

      yield Candidates::Change.new(
        candidate:,
        actor_account:,
        params: { recruiter_id: recruiter.id }
      ).call

      yield Tasks::Add.new(
        actor_account:,
        params: {
          assignee_id: candidate.recruiter_id,
          taskable_id: candidate.id,
          taskable_type: "Candidate",
          name: "Reply to application to #{position.name}",
          due_date: Time.zone.today.next_weekday
        }
      ).call

      candidate
    end

    # File uploading did not work correctly inside the main transaction.
    case Candidates::UploadFile.new(candidate:, actor_account:, file:, cv: true).call
    in Success(_)
      Success()
    in Failure[:file_invalid, e]
      candidate.destroy!
      Failure[:file_invalid, e]
    end
  end
end
