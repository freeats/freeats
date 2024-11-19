# frozen_string_literal: true

class Candidates::UploadFile < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :candidate, Types::Instance(Candidate)
  option :actor_account, Types::Instance(Account).optional
  option :file, Types::Instance(ActionDispatch::Http::UploadedFile)
  option :cv, Types::Strict::Bool.optional, default: proc { false }

  def call
    ActiveRecord::Base.transaction do
      attachment = yield upload_file(candidate:, file:, cv:)
      add_event(attachment:, file:, actor_account:)
    end

    Success(candidate.files.last)
  end

  private

  def upload_file(candidate:, file:, cv:)
    attachment = candidate.files.attach(file).attachments.last
    attachment.change_cv_status(actor_account) if cv

    Success(attachment)
  rescue ActiveRecord::RecordInvalid => e
    Failure[:file_invalid, e.to_s]
  end

  def add_event(attachment:, file:, actor_account:)
    properties = { name: file.original_filename }

    Event.create!(
      type: :active_storage_attachment_added,
      eventable: attachment,
      properties:,
      actor_account:
    )
  end
end
