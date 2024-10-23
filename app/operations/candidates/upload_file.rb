# frozen_string_literal: true

class Candidates::UploadFile < ApplicationOperation
  include Dry::Monads[:result, :try]

  option :candidate, Types::Instance(Candidate)
  option :actor_account, Types::Instance(Account).optional
  option :file, Types::Instance(ActionDispatch::Http::UploadedFile)
  option :cv, Types::Strict::Bool.optional, default: proc { false }

  def call
    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        attachment = candidate.files.attach(file).attachments.last

        Events::Add.new(
          params:
            {
              type: :active_storage_attachment_added,
              eventable: attachment,
              properties: { name: file.original_filename },
              actor_account:
            }
        ).call

        attachment.change_cv_status(actor_account) if cv
      end
    end.to_result

    case result
    in Success(_)
      Success(candidate.files.last)
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:validation_failed, e.to_s]
    end
  end
end
