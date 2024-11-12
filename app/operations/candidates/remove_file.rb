# frozen_string_literal: true

class Candidates::RemoveFile < ApplicationOperation
  include Dry::Monads[:result, :try]

  option :candidate, Types::Instance(Candidate)
  option :actor_account, Types::Instance(Account)
  option :file, Types::Instance(ActiveStorage::Attachment)

  def call
    result = Try[ActiveRecord::RecordInvalid] do
      ActiveRecord::Base.transaction do
        Events::Add.new(
          params:
            {
              type: :active_storage_attachment_removed,
              eventable: candidate,
              properties: {
                name: file.blob.filename,
                active_storage_attachment_id: file.id,
                added_actor_account_id: file.added_event.actor_account_id,
                added_at: file.added_event.performed_at
              },
              actor_account:
            }
        ).call
        file.remove
      end

      nil
    end.to_result

    case result
    in Success(_)
      Success()
    in Failure[ActiveRecord::RecordInvalid => e]
      Failure[:file_invalid, e.to_s]
    end
  end
end
