# frozen_string_literal: true

class Candidates::UploadFile
  include Dry::Monads[:result, :try]

  include Dry::Initializer.define -> do
    option :candidate, Types::Instance(Candidate)
    option :actor_account, Types::Instance(Account)
    option :file, Types::Instance(ActionDispatch::Http::UploadedFile)
    option :cv, Types::Strict::Bool.optional, default: proc { false }
  end

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

        attachment.change_cv_status(true, actor_account) if cv
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
