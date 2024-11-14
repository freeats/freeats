# frozen_string_literal: true

class Candidates::UploadFile < ApplicationOperation
  include Dry::Monads[:result, :try]

  option :candidate, Types::Instance(Candidate)
  option :actor_account, Types::Instance(Account).optional
  option :file, Types::Instance(ActionDispatch::Http::UploadedFile)
  option :cv, Types::Strict::Bool.optional, default: proc { false }
  option :custom_metadata, Types::Strict::Hash.optional, default: proc { {} }

  def call
    ActiveRecord::Base.transaction do
      attachment = candidate.files.attach(file).attachments.last

      attachment.blob.custom_metadata = custom_metadata

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

    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:file_invalid, e.to_s]
  end
end
