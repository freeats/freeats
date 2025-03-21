# frozen_string_literal: true

class Candidates::Apply < ApplicationOperation
  include Dry::Monads[:result, :do, :try]

  option :actor_account, Types::Instance(Account).optional
  option :method, Types::Strict::String, default: -> { "applied" }
  option :params, Types::Strict::Hash.schema(
    email: Types::Strict::String,
    file: Types::Instance(ActionDispatch::Http::UploadedFile),
    full_name: Types::Strict::String
  )
  option :position_id, Types::Coercible::Integer

  def call
    position = Position.find(position_id)
    recruiter = position.recruiter
    return Failure(:no_active_recruiter) if recruiter.blank? || recruiter.inactive?

    candidate_email_addresses =
      [{
        address: params[:email],
        status: "current",
        source: "other",
        type: "personal",
        created_via: "applied"
      }]
    candidate_params =
      { full_name: params[:full_name], emails: candidate_email_addresses,
        recruiter_id: recruiter.id }
    file = params[:file]

    candidate = Candidate.transaction do
      candidate =
        yield Candidates::Add.new(params: candidate_params, actor_account:, method:).call

      placement = yield Placements::Add.new(
        params: { candidate_id: candidate.id, position_id: },
        actor_account:,
        applied: true
      ).call

      yield Placements::ChangeStage.new(new_stage: "Replied", placement:, actor_account:).call

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
    case Candidates::UploadFile
      .new(candidate:, actor_account:, file:, cv: true, namespace: :career_site)
      .call
    in Success() | Failure(:file_already_present)
      Success()
    in Failure[:file_invalid, e]
      candidate.destroy!
      Failure[:file_invalid, e]
    end
  end
end
