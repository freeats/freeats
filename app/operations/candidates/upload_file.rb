# frozen_string_literal: true

class Candidates::UploadFile < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :candidate, Types::Instance(Candidate)
  option :actor_account, Types::Instance(Account).optional, optional: true
  option :file, Types::Instance(ActionDispatch::Http::UploadedFile)
  option :cv, Types::Strict::Bool.optional, default: proc { false }
  option :source, Types::Strict::String.optional, default: proc { "" }
  option :namespace, Types::Strict::Symbol

  def call
    if file.content_type == "application/pdf"
      yield Candidates::UploadPDFFile
        .new(candidate:, actor_account:, file:, cv:, source:, namespace:)
        .call
    else
      yield upload_not_pdf_file(candidate:, file:, cv:, actor_account:)
    end

    update_profile_from_cv(candidate:, file:, actor_account:) if cv

    Success()
  end

  private

  def upload_not_pdf_file(candidate:, file:, cv:, actor_account:)
    ActiveRecord::Base.transaction do
      attachment = yield upload(candidate:, file:, cv:)
      add_event(attachment:, file:, actor_account:)
    end

    Success()
  end

  def upload(candidate:, file:, cv:)
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

  def update_profile_from_cv(candidate:, file:, actor_account:)
    case Candidates::UpdateFromCV.new(
      cv_file: file,
      candidate:,
      actor_account:
    ).call
    in Success() | Failure(:unsupported_file_format) | Failure(:parse_failed) |
       Failure(:contacts_not_updated)
      nil
    end
  end
end
